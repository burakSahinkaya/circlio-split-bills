import * as admin from "firebase-admin";
import { onDocumentWritten, onDocumentCreated } from "firebase-functions/v2/firestore";

admin.initializeApp();

export const onGroupUpdated = onDocumentWritten("groups/{groupId}", async (event) => {
  const beforeData = event.data?.before.data();
  const afterData = event.data?.after.data();

  // If document was deleted, do nothing
  if (!afterData) return;

  const beforePending: string[] = beforeData?.pendingMemberIds || [];
  const afterPending: string[] = afterData?.pendingMemberIds || [];

  // Find newly invited user IDs
  const newlyInvitedIds = afterPending.filter((id) => !beforePending.includes(id));

  if (newlyInvitedIds.length === 0) return;

  const groupName = afterData.name || "A new group";
  const db = admin.firestore();
  
  // Send a notification to each newly invited user
  const promises = newlyInvitedIds.map(async (userId) => {
    try {
      const userDoc = await db.collection("users").doc(userId).get();
      if (!userDoc.exists) return;

      const userData = userDoc.data();
      const fcmTokens: string[] = userData?.fcmTokens || [];

      if (fcmTokens.length === 0) {
        console.log(`User ${userId} has no FCM tokens.`);
        return;
      }

      const message = {
        notification: {
          title: "Group Invitation",
          body: `You've been invited to join ${groupName}`,
        },
        data: {
          groupId: event.params.groupId,
          type: "group_invite",
        },
        tokens: fcmTokens,
      };

      const response = await admin.messaging().sendEachForMulticast(message);
      console.log(`Successfully sent message to ${userId}, successes: ${response.successCount}, failures: ${response.failureCount}`);
    } catch (error) {
      console.error(`Error sending message to ${userId}:`, error);
    }
  });

  await Promise.all(promises);
});

export const onExpenseCreated = onDocumentCreated("groups/{groupId}/expenses/{expenseId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) return;

  const data = snapshot.data();
  const groupId = event.params.groupId;

  const creatorId = data.createdBy;
  const paidById = data.paidById;
  const splits = data.splits || [];
  const isPayment = data.isPayment || false;
  const description = data.description || (isPayment ? "Payment recorded" : "New expense added");

  const db = admin.firestore();

  // Update the group's lastActivityAt timestamp
  try {
    await db.collection("groups").doc(groupId).update({
      lastActivityAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (e) {
    console.error("Error updating group lastActivityAt:", e);
  }

  // Collect all users involved in this expense
  const targetUserIds = new Set<string>();
  
  if (paidById) targetUserIds.add(paidById);
  splits.forEach((split: any) => {
    if (split.userId) targetUserIds.add(split.userId);
  });

  // DO NOT notify the user who created the record
  if (creatorId) {
    targetUserIds.delete(creatorId);
  }

  // If no one left to notify, exit
  if (targetUserIds.size === 0) return;

  // Fetch the group to get its name for the notification title
  let groupName = "Your Group";
  try {
    const groupDoc = await db.collection("groups").doc(groupId).get();
    if (groupDoc.exists) {
      groupName = groupDoc.data()?.name || "Your Group";
    }
  } catch (e) {
    console.error("Error fetching group document:", e);
  }

  // Send a notification to each involved user
  const promises = Array.from(targetUserIds).map(async (userId) => {
    try {
      const userRef = db.collection("users").doc(userId);
      const userDoc = await userRef.get();
      if (!userDoc.exists) return;

      const userData = userDoc.data() || {};
      const fcmTokens: string[] = userData.fcmTokens || [];

      // Calculate new badge counts
      const unreadCounts = userData.unreadCounts || {};
      const currentGroupCount = unreadCounts[groupId] || 0;
      unreadCounts[groupId] = currentGroupCount + 1;
      
      const newTotalUnreadCount = (userData.totalUnreadCount || 0) + 1;

      // Persist the new incremented counts
      await userRef.update({
        unreadCounts: unreadCounts,
        totalUnreadCount: newTotalUnreadCount,
      });

      // If they have no tokens, skip push
      if (fcmTokens.length === 0) {
        console.log(`User ${userId} has no FCM tokens.`);
        return;
      }

      const message = {
        notification: {
          title: `${groupName} Activity`,
          body: isPayment 
            ? `A payment was recorded involving you in ${groupName}` 
            : `A new expense "${description}" involves you`,
        },
        apns: {
          payload: {
            aps: {
              badge: newTotalUnreadCount,
              sound: "default",
            },
          },
        },
        data: {
          groupId: groupId,
          expenseId: event.params.expenseId,
          type: "expense_activity",
        },
        tokens: fcmTokens,
      };

      const response = await admin.messaging().sendEachForMulticast(message);
      console.log(`Successfully sent expense message to ${userId}, successes: ${response.successCount}`);
    } catch (error) {
      console.error(`Error sending expense message to ${userId}:`, error);
    }
  });

  await Promise.all(promises);
});
