import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:math_parser/math_parser.dart';

const successS = 'success';

Widget loadingCenter() {
  return const Center(
    child: CircularProgressIndicator(),
  );
}

// Widget textF(TextEditingController controller) {
//   return IntrinsicWidth(
//     child: TextField(
//       controller: controller,
//       decoration: const InputDecoration(isDense: true),
//       // onChanged: (value) => ,
//     ),
//   );
// }

formatDate1(DateTime date) {
  return DateFormat('dd/MM/yy').format(date);
}

calc(String equation) {
  try {
    return MathNodeExpression.fromString(equation)
        .calc(MathVariableValues.none)
        .toDouble();
  } catch (e) {
    return 0;
  }
}