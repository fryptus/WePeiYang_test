import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:provider/provider.dart';
import 'package:we_pei_yang_flutter/message/model/message_provider.dart';

class FeedbackBannerWidget extends StatelessWidget {
  final int questionId;
  final bool showBanner;
  final Widget Function(VoidFutureCallBack? tap) builder;

  const FeedbackBannerWidget(
      {Key? key,
      required this.questionId,
      this.showBanner = false,
      required this.builder})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (showBanner) {
      return Consumer<MessageProvider>(builder: (__, model, _) {
        Widget result;
        // if (model.inMessageList(questionId)) {
        //   VoidFutureCallBack tap = () async {
        //     await model.setAllMessageRead(questionId);
        //   };
        //   result = ClipRect(
        //     child: Banner(
        //       message: S.current.not_read,
        //       location: BannerLocation.bottomEnd,
        //       child: builder(tap),
        //     ),
        //   );
        // } else {
        result = builder(null);
        // }

        return result;
      });
    } else {
      return builder(null);
    }
  }
}
