import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
// import 'package:jarvis_0/todo/task_widget.dart';
import 'package:jarvis_0/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firestore_methods.dart';
import '/todo/task_model.dart';

class TodoM {
  static final _prefs = SharedPreferences.getInstance();
  static final _firestore = FirebaseFirestore.instance;

  static Future displayDialog(
    Map<String, Task> tasks,
    TextEditingController titleC,
    BuildContext context,
    SyncObj sO,
  ) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add a task'),
        content: TextField(
          controller: titleC,
          decoration: const InputDecoration(hintText: 'Type your task'),
          autofocus: true,
          onSubmitted: (value) {
            Navigator.of(context).pop();
            addTask(tasks, titleC, sO);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              addTask(tasks, titleC, sO);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  static void loadSyncTasks(Map<String, Task> tasks, SyncObj sO) {
    syncFun(sO, () => _loadTasks(tasks));
    syncFun(sO, () => _syncTasks(tasks));
  }

  static void syncTasks(Map<String, Task> tasks, SyncObj sO) {
    syncFun(sO, () => _syncTasks(tasks));
  }

  static void addTask(
      Map<String, Task> tasks, TextEditingController titleC, SyncObj sO) {
    try {
      final task = Task(title: titleC.text);
      tasks[task.uid] = task;
      titleC.clear();
      _saveTask(TaskObj(tasks, task), sO);
    } catch (e) {
      print(e);
    }
  }

  static void archiveTask(TaskObj tO, SyncObj sO) {
    try {
      tO.task.dispose();
      tO.tasks.remove(tO.task.uid);
      syncFun(sO, () {
        _saveTasksLocally(tO.tasks);
        FirestoreMethdods.archiveTask(tO.task.uid);
      });
    } catch (e) {
      print(e);
    }
  }

  static void doneTask(TaskObj tO, SyncObj sO) {
    try {
      tO.task.dispose();
      tO.tasks.remove(tO.task.uid);
      syncFun(sO, () {
        _saveTasksLocally(tO.tasks);
        FirestoreMethdods.doneTask(tO.task.uid);
      });
    } catch (e) {
      print(e);
    }
  }

  static void modifyTitle(TaskObj tO, String title, SyncObj sO) {
    try {
      tO.task.title = title;
      tO.task.lastModified = DateTime.now();
      _saveTask(TaskObj(tO.tasks, tO.task), sO);
    } catch (e) {
      print(e);
    }
  }

  static void modifyDate(
      String uid, Map<String, Task> tasks, SyncObj sO) async {
    try {
      Task task = tasks[uid]!;
      if (task.date != null) task.dueDate = task.date;
      task.dueDate ??= DateTime.now();
      if (task.time != null) {
        task.dueDate = DateTime(
          task.dueDate!.year,
          task.dueDate!.month,
          task.dueDate!.day,
          task.time!.hour,
          task.time!.minute,
        );
      }
      // check with text
      task.lastModified = DateTime.now();
      tasks[uid] = task;
      task.isDateVisible = false;
      _saveTask(TaskObj(tasks, task), sO);
    } catch (e) {
      print(e);
    }
  }

  static void textToDate(String dateString, TaskObj tO, SyncObj sO) {
    // make green the expressions
    try {
      final nowYear = DateTime.now().year;

      // find format 1: 3 jul/10 jul
      RegExp r = RegExp(
          r"\b(3[01]|[12][0-9]|[1-9])\s(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)",
          caseSensitive: false);
      final match = r.firstMatch(dateString);

      if (match != null) {
        String matchedDate = match.group(0)!;
        String monthAbbreviation = matchedDate.split(' ')[1].toLowerCase();
        int? monthIndex = monthMap[monthAbbreviation];
        String formattedDate =
            matchedDate.replaceFirst(monthAbbreviation, monthIndex.toString());
        DateFormat format = DateFormat("d M y", "en_US");
        DateTime dateTime = format.parse('$formattedDate $nowYear');
        print(dateTime);
      } else {}

      // find format 2: 3.6
    } catch (e) {
      print(e);
    }
  }

  static void _saveTask(TaskObj tO, SyncObj sO) {
    syncFun(sO, () {
      _saveTasksLocally(tO.tasks);
      FirestoreMethdods.addOrModifyTask(tO.task);
    });
  }

  static Future<void> _loadTasks(Map<String, Task> tasks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(tasksS);
      final taskMap = json.decode(jsonString!);
      tasks.clear();
      taskMap.forEach((key, value) {
        tasks[key] = Task.fromJson(key, value);
      });
    } catch (e) {
      print(e);
    }
  }

  static Future<void> _saveTasksLocally(Map<String, Task> tasks) async {
    try {
      final prefs = await _prefs;
      final taskMap = tasks.map((key, value) => MapEntry(key, value.toJson()));
      await prefs.setString(tasksS, json.encode(taskMap));
    } catch (e) {
      print(e);
    }
  }

  static Future<void> _syncTasks(Map<String, Task> tasks) async {
    try {
      final List results = await Future.wait([
        _prefs,
        _firestore.collection(tasksS).get(),
        _firestore.collection(tasksArchivedS).get(),
        _firestore.collection(tasksDoneS).get(),
      ]);
      final snapArchived = results[2];
      final snapDone = results[3];
      final jsonString = results[0].getString(tasksS);
      final docs = results[1].docs;
      tasks.clear();
      if (jsonString != null) {
        final taskMap = json.decode(jsonString);
        for (var entry in taskMap.entries) {
          final uid = entry.key;
          final taskPrefs = Task.fromJson(uid, entry.value);
          if (docs.contains(uid)) {
            final taskFirestore =
                Task.fromSnap(docs.firstWhere((element) => element.id == uid));
            if (taskFirestore.lastModified.isAfter(taskPrefs.lastModified)) {
              tasks[uid] = taskFirestore;
              continue;
            }
          }
          if (snapArchived.docs.contains(uid) || snapDone.docs.contains(uid)) {
            continue;
          }
          tasks[uid] = taskPrefs;
          FirestoreMethdods.addOrModifyTask(taskPrefs);
        }
      }
      for (var doc in docs) {
        if (!tasks.containsKey(doc.id)) {
          tasks[doc.id] = Task.fromSnap(doc);
        }
      }
      await _saveTasksLocally(tasks);
    } catch (e) {
      print(e);
    }
  }
}

Future<void> syncFun(SyncObj sO, Function callback) async {
  sO.setState(() {
    sO.isSyncing.value = true;
  });
  await callback();
  sO.setState(() {
    sO.isSyncing.value = false;
  });
}

class SyncObj {
  final StateSetter setState;
  final BoolWrapper isSyncing;

  SyncObj(this.setState, this.isSyncing);
}

class TaskObj {
  final Map<String, Task> tasks;
  final Task task;

  TaskObj(this.tasks, this.task);
}

Map<String, int> monthMap = {
  'jan': 1,
  'feb': 2,
  'mar': 3,
  'apr': 4,
  'may': 5,
  'jun': 6,
  'jul': 7,
  'aug': 8,
  'sep': 9,
  'oct': 10,
  'nov': 11,
  'dec': 12,
};