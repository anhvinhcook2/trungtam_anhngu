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

    return {
      success: true,
      message: `Đã xóa thành công người dùng!`,
    };
  } catch (error) {
    console.error("Lỗi khi xóa:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});
