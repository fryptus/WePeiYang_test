import 'package:flutter/material.dart';
import 'package:we_pei_yang_flutter/message/model/message_provider.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;

class FeedbackBadgeWidget extends StatefulWidget {
  final Widget child;

  const FeedbackBadgeWidget({Key? key, required this.child}) : super(key: key);

  @override
  _FeedbackBadgeWidgetState createState() => _FeedbackBadgeWidgetState();
}

class _FeedbackBadgeWidgetState extends State<FeedbackBadgeWidget> {
  @override
  Widget build(BuildContext context) {
    int count = context.select((MessageProvider messageProvider) =>
        messageProvider.messageCount.total);
    return count == 0
        ? widget.child
        : badges.Badge(
            badgeContent: Padding(
              padding: EdgeInsets.all(4),
              child: Text(
                count.toString(),
                style: TextStyle(color: Colors.white, fontSize: 7),
              ),
            ),
            child: widget.child,
          );
  }
}
