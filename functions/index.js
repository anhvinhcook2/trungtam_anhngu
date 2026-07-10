const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.deleteUserAccount = functions.https.onCall(async (data, context) => {
  // Lấy UID của Admin và UID của người cần xóa do App gửi lên
  const adminUid = data.adminUid;
  const targetUid = data.uid;

  // 1. Kiểm tra xem App có gửi Admin UID lên không
  if (!adminUid) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "Không nhận diện được tài khoản Admin trên App.",
    );
  }

  try {
    const callerDoc = await admin
        .firestore()
        .collection("users")
        .doc(adminUid)
        .get();
    const userData = callerDoc.data();

    if (!userData || userData.role !== "admin") {
      throw new functions.https.HttpsError(
          "permission-denied",
          "Chỉ Quản trị viên (Admin) mới có quyền xóa tài khoản.",
      );
    }

    // 3. Xóa thông tin trong Firebase Authentication
    await admin.auth().deleteUser(targetUid);

    // 4. Xóa thông tin trong Cloud Firestore
    await admin.firestore().collection("users").doc(targetUid).delete();
    
    // 5. Xóa ID học sinh khỏi tất cả các lớp học
    const classesSnapshot = await admin.firestore()
        .collection("classes")
        .where("studentIds", "array-contains", targetUid)
        .get();

    const batch = admin.firestore().batch();
    classesSnapshot.docs.forEach((doc) => {
      batch.update(doc.ref, {
        studentIds: admin.firestore.FieldValue.arrayRemove(targetUid),
      });
    });
    await batch.commit();

    return {
      success: true,
      message: `Đã xóa thành công người dùng và cập nhật các lớp học!`,
    };
  } catch (error) {
    console.error("Lỗi khi xóa:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});
