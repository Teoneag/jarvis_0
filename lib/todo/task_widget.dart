import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_time_picker_spinner/flutter_time_picker_spinner.dart';
import 'package:jarvis_0/utils/utils.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'task_model.dart';
import 'todo_methdos.dart';

class TaskWidget extends StatelessWidget {
  final Map<String, Task> tasks;
  final Task task;
  final StateSetter setState;
  final BoolWrapper isSyncing;
  const TaskWidget(this.tasks, this.task, this.setState, this.isSyncing,
      {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          // key: ValueKey(task.uid), // only for reordering (not doing now)
          leading: IconButton(
            icon: const Icon(Icons.check_box_outline_blank),
            onPressed: () => TodoM.markDoneTask(
              tasks,
              task,
              setState,
              isSyncing,
            ),
          ),
          title: TextField(
            controller: task.titleC,
            decoration:
                const InputDecoration(isDense: true, border: InputBorder.none),
            // change onChanged to onSubmitted
            onChanged: (title) =>
                TodoM.modifyTitle(title, tasks, task, setState, isSyncing),
          ),
          subtitle: Column(
            children: [
              IntrinsicWidth(
                child: TextField(
                  controller: task.dateC,
                  onTap: () {
                    task.isDateVisible = true;
                    setState(() {});
                  },
                  onSubmitted: (value) {
                    task.isDateVisible = false;
                    setState(() {});
                  },
                  decoration: const InputDecoration(
                    hintText: 'Date',
                    isDense: true,
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
          trailing: Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () =>
                  TodoM.archiveTask(tasks, task, setState, isSyncing),
            ),
          ),
        ),
        Visibility(
          visible: task.isDateVisible,
          child: Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Row(
              children: [
                Expanded(
                  child: SfDateRangePicker(
                    // format text
                    onSelectionChanged: (date) => task.date = date.value,
                    initialSelectedDate: task.dueDate,
                  ),
                ),
                Column(
                  children: [
                    TimePickerSpinner(
                      normalTextStyle: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                      ),
                      highlightedTextStyle: const TextStyle(
                        fontSize: 30,
                        color: Colors.blue,
                      ),
                      time: task.dueDate,
                      // format text
                      onTimeChange: (time) => task.time = time,
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              task.isDateVisible = false;
                            });
                            FocusScope.of(context).unfocus();
                            SystemChannels.textInput
                                .invokeMethod('TextInput.hide');
                          },
                          icon: const Icon(Icons.close),
                        ),
                        IconButton(
                          onPressed: () {
                            FocusScope.of(context).unfocus();
                            SystemChannels.textInput
                                .invokeMethod('TextInput.hide');
                            TodoM.modifyDate(
                                task.uid, tasks, setState, isSyncing);
                          },
                          icon: const Icon(Icons.check),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
