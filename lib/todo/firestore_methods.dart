import 'package:cloud_firestore/cloud_firestore.dart';
import '/todo/task_model.dart';
import '/utils/utils.dart';
import 'tag_model.dart';

const tasksS = 'tasks';
const tasksArchivedS = 'tasksArchived';
const tasksDoneS = 'tasksDone';
const tagsS = 'tags';

class FirestoreM {
  static final _firestore = FirebaseFirestore.instance;

  static Future<String> addOrModifyTag(Tag tag) async {
    try {
      await _firestore.collection(tagsS).doc(tag.title).set(tag.toJson());
      return successS;
    } catch (e) {
      print(e);
      return '$e';
    }
  }

  static Future<String> addOrModifyTask(Task task) async {
    try {
      await _firestore.collection(tasksS).doc(task.uid).set(task.toJson());
      return successS;
    } catch (e) {
      print(e);
      return '$e';
    }
  }

  static Future<String> archiveTask(String uid) async {
    try {
      final docSnap = await _firestore.collection(tasksS).doc(uid).get();
      await _firestore.collection(tasksArchivedS).doc(uid).set(docSnap.data()!);
      await _firestore.collection(tasksS).doc(uid).delete();
      return successS;
    } catch (e) {
      print(e);
      return '$e';
    }
  }

  static Future<String> doneTask(String uid) async {
    try {
      final docSnap = await _firestore.collection(tasksS).doc(uid).get();
      await _firestore.collection(tasksDoneS).doc(uid).set(docSnap.data()!);
      await _firestore.collection(tasksS).doc(uid).delete();
      return successS;
    } catch (e) {
      print(e);
      return '$e';
    }
  }

  static Future<Task> getTask(String uid) async {
    try {
      print('Getting task');
      final docSnap = await _firestore.collection(tasksS).doc(uid).get();
      return Task.fromSnap(docSnap);
    } catch (e) {
      print(e);
      return Task(title: 'Error');
    }
  }
}
