import 'package:flutter/material.dart';

class SelectItem<T> {
  final T value;
  final String label;
  const SelectItem({required this.value, required this.label});
}

/// 自定义下拉选项按钮
class CustomDropdownButton<T> extends StatelessWidget {
  final List<SelectItem<T>> items;
  final T? initialSelection;
  final void Function(T) onSelected;

  const CustomDropdownButton({
    super.key,
    required this.items,
    required this.initialSelection,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<T>(
      value: initialSelection,
      underline: const SizedBox(), // 去掉下划线
      style: const TextStyle(
        fontSize: 16,
        color: Colors.black,
      ),
      borderRadius: BorderRadius.circular(8), // 圆角
      focusColor: Colors.transparent, // 下拉框按钮背景颜色
      dropdownColor: Colors.white, // 下拉菜单背景颜色
      // 下拉菜单图标
      icon: const Padding(
        padding: EdgeInsets.only(left: 4),
        child: Icon(Icons.arrow_drop_down, size: 18),
      ),
      iconSize: 18,
      onChanged: (value) {
        if (value != null) onSelected(value);
      },
      // 下拉选项
      itemHeight: 48, // 单个选项高度
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item.value,
          child: Text(item.label),
        );
      }).toList(),
    );
  }
}


// import 'package:flutter/material.dart';

// class SelectItem<T> {
//   final T value;
//   final String label;

//   const SelectItem({
//     required this.value,
//     required this.label,
//   });
// }

// class CustomDropdownMenu<T> extends StatelessWidget {
//   final T? initialSelection;
//   final List<SelectItem<T>> dropdownMenuEntries;
//   final ValueChanged<T> onSelected;
//   const CustomDropdownMenu(
//       {super.key,
//       required this.initialSelection,
//       required this.onSelected,
//       required this.dropdownMenuEntries});

//   @override
//   Widget build(BuildContext context) {
//     return DropdownMenu<T>(
//       initialSelection: initialSelection,
//       onSelected: (value) {
//         if (value != null) {
//           onSelected(value);
//         }
//       },
//       // 自定义输入框样式
//       inputDecorationTheme: InputDecorationTheme(
//         constraints: const BoxConstraints(maxHeight: 38),
//         contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
//         filled: true,
//         fillColor: Colors.grey[50], // 浅灰色背景
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(8), // 圆角
//           borderSide: const BorderSide(color: Colors.grey),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(8),
//           borderSide: BorderSide(color: Colors.grey.shade300),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(8),
//           borderSide:
//               const BorderSide(color: Colors.blue, width: 1.5), // 选中时蓝色边框
//         ),
//         isDense: true,
//       ),
//       // trailingIcon: const SizedBox(
//       //   width: 10, // 控制宽度
//       //   height: 10, // 控制高度
//       //   child: Icon(
//       //     Icons.arrow_drop_down,
//       //     size: 18,
//       //   ),
//       // ),
//       trailingIcon: Container(
//         width: 10,    // 直接限制点击区域宽度
//         height: 10,   // 直接限制点击区域高度
//         alignment: Alignment.center,
//         child: const Icon(
//           Icons.arrow_drop_down,
//           size: 18,   // 图标大小
//         ),
//       ),
//       selectedTrailingIcon: const SizedBox(
//         width: 10, // 控制宽度
//         height: 10, // 控制高度
//         child: Icon(
//           Icons.arrow_drop_up,
//           size: 18,
//         ),
//       ),
//       dropdownMenuEntries: dropdownMenuEntries.map((item) {
//         return DropdownMenuEntry<T>(
//           value: item.value,
//           label: item.label,
//         );
//       }).toList(),
//     );
//   }
// }

