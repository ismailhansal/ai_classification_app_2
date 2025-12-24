import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

import '../../../model/menu.dart';
import '../../../model/rive_model.dart';
import '../../../utils/rive_utils.dart';
import 'info_card.dart';
import 'side_menu.dart';

class SideBar extends StatefulWidget {
  const SideBar({super.key, required this.onSectionSelected});

  final ValueChanged<String> onSectionSelected;

  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {
  Menu selectedSideMenu = sidebarMenus.first;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        width: 288,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFF17203A),
          borderRadius: BorderRadius.all(
            Radius.circular(30),
          ),
        ),
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.white),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const InfoCard(
                name: "Ismail HANSAL",
                bio: "Engineer",
              ),
              Padding(
                padding: const EdgeInsets.only(left: 24, top: 32, bottom: 16),
                child: Text(
                  "Browse".toUpperCase(),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium!
                      .copyWith(color: Colors.white70),
                ),
              ),
              ...sidebarMenus.map((menu) => SideMenu(
                    menu: menu,
                    selectedMenu: selectedSideMenu,
                    press: () {
                      RiveUtils.chnageSMIBoolState(menu.rive.status!);
                      setState(() {
                        selectedSideMenu = menu;
                      });
                      widget.onSectionSelected(menu.title);
                    },
                    riveOnInit: (artboard) {
                      menu.rive.status =
                          RiveUtils.getRiveInput(artboard,
                              stateMachineName: menu.rive.stateMachineName);
                    },
                  )),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(left: 24, bottom: 16),
                child: Text(
                  "More",
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium!
                      .copyWith(color: Colors.white70),
                ),
              ),
              ...sidebarMenus2.map((menu) => SideMenu(
                    menu: menu,
                    selectedMenu: selectedSideMenu,
                    press: () {
                      RiveUtils.chnageSMIBoolState(menu.rive.status!);
                      setState(() {
                        selectedSideMenu = menu;
                      });

                      if (menu.title == "ANN" ||
                          menu.title == "CNN" ||
                          menu.title == "LSTM" ||
                          menu.title == "RAG") {
                        widget.onSectionSelected(menu.title);
                      }
                    },
                    riveOnInit: (artboard) {
                      menu.rive.status = RiveUtils.getRiveInput(artboard,
                          stateMachineName: menu.rive.stateMachineName);
                    },
                  )),
              Padding(
                padding: const EdgeInsets.only(left: 24, top: 40, bottom: 16),
                child: Text(
                  "AI Assistant".toUpperCase(),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium!
                      .copyWith(color: Colors.white70),
                ),
              ),
              SideMenu(
                menu: Menu(
                  title: "AI Assistant",
                  rive: RiveModel(
                    src: "assets/RiveAssets/icons.riv",
                    artboard: "CHAT",
                    stateMachineName: "CHAT_Interactivity",
                  ),
                ),
                selectedMenu: selectedSideMenu,
                press: () {
                  setState(() {
                    selectedSideMenu = Menu(
                      title: "AI Assistant",
                      rive: RiveModel(
                        src: "assets/RiveAssets/icons.riv",
                        artboard: "CHAT",
                        stateMachineName: "CHAT_Interactivity",
                      ),
                    );
                  });
                  widget.onSectionSelected("AI Assistant");
                },
                riveOnInit: (artboard) {
                  final controller = StateMachineController.fromArtboard(artboard, "CHAT_Interactivity");
                  if (controller != null) {
                    artboard.addController(controller);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
