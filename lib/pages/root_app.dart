import 'package:fitness_ui_kit/pages/home_page.dart';
import 'package:fitness_ui_kit/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'home_page.dart';

// 新增的蓝牙和数据展示页面
import 'bluetooth_devices_page.dart';
import 'data_display_page.dart';

class RootApp extends StatefulWidget {
  const RootApp({Key? key}) : super(key: key);

  @override
  _RootAppState createState() => _RootAppState();
}

class _RootAppState extends State<RootApp> {
  int pageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: getBody(),
      bottomNavigationBar: getFooter(),
    );
  }

  // 1) 在 IndexedStack 中放置 5 个页面
  //    第 3 个是蓝牙页面，第 4 个是数据展示页面，第 5 个是个人页面
  Widget getBody() {
    return IndexedStack(
      index: pageIndex,
      children: [
        HomePage(),
        Center(child: Text("Chart")),
        BluetoothDevicesPage(), // 用蓝牙设备页面替换 Camera
        DataDisplayPage(),      // 新增数据展示页面
        Center(child: Text("Profile")),
      ],
    );
  }

  // 2) 更新底部导航栏图标和数量
  //    [Home, Chart, Bluetooth, Data, User]
  Widget getFooter() {
    List items = [
      LineIcons.home,        // 首页
      LineIcons.pieChart,    // 图表
      Icons.bluetooth,       // 蓝牙
      Icons.data_usage,      // 数据
      LineIcons.user         // 用户/个人中心
    ];
    return Container(
      height: 90,
      width: double.infinity,
      decoration: BoxDecoration(
        color: white,
        border: Border(top: BorderSide(width: 1, color: black.withOpacity(0.06))),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(items.length, (index) {
            return InkWell(
              onTap: () {
                setState(() {
                  pageIndex = index;
                });
              },
              child: Column(
                children: [
                  Icon(
                    items[index],
                    size: 28,
                    color: pageIndex == index ? thirdColor : black,
                  ),
                  const SizedBox(height: 5),
                  pageIndex == index
                      ? Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: thirdColor,
                      shape: BoxShape.circle,
                    ),
                  )
                      : Container(),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
