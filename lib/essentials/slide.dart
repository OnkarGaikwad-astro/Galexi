import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class MessageTile extends StatefulWidget {
  final dynamic message;
  final int realIndex;
  final Widget child;
  final Function onReply;
  final Function onDelete;

  const MessageTile({
    super.key,
    required this.message,
    required this.realIndex,
    required this.child,
    required this.onReply,
    required this.onDelete,
  });

  @override
  State<MessageTile> createState() => _MessageTileState();
}

class _MessageTileState extends State<MessageTile>
    with SingleTickerProviderStateMixin {
  late final SlidableController controller;

  bool triggered = false;
  ActionPaneType? currentPane;
  bool isDragging = false;

  @override
  void initState() {
    super.initState();

    controller = SlidableController(this);

    controller.animation.addListener(() {
      final value = controller.animation.value;

      // detect which pane is opening (ONLY ONCE)
      currentPane ??= controller.actionPaneType.value;

      // trigger only once
      if (!triggered && value > 0.4 && currentPane != null) {
        triggered = true;

        if (currentPane == ActionPaneType.start) {
          widget.onReply();   // 👉 right swipe
        } else {
          widget.onDelete();  // 👈 left swipe
        }

        controller.close();
      }
    });

    controller.animation.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        triggered = false;
        currentPane = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Slidable(
      controller: controller,
      key: ValueKey(widget.message["id"]),
      groupTag: 'chatMessages',

      // 👉 Right swipe → Reply
      startActionPane: const ActionPane(
        motion: StretchMotion(),
        children: [
          SlidableAction(
            onPressed: null,
            borderRadius: BorderRadius.all(Radius.circular(20)),
            backgroundColor: Color.fromARGB(158, 33, 243, 61),
            spacing: BorderSide.strokeAlignOutside,
            icon: Icons.reply,
            // label: 'Reply',
          ),
        ],
      ),

      // 👉 Left swipe → Delete
      endActionPane: const ActionPane(
        motion: DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: null,
            borderRadius: BorderRadius.all(Radius.circular(20)),
            //  spacing: BorderSide.strokeAlignOutside,
            backgroundColor: Colors.red,
            icon: Icons.delete,
            // label: 'Delete',
          ),
        ],
      ),

      child: widget.child,
    );
  }
}