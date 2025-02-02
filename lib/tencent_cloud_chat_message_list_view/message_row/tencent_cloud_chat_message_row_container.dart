import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tencent_cloud_chat/components/components_definition/tencent_cloud_chat_component_builder_definitions.dart';
import 'package:tencent_cloud_chat/components/tencent_cloud_chat_components_utils.dart';
import 'package:tencent_cloud_chat/data/message/tencent_cloud_chat_message_data.dart';
import 'package:tencent_cloud_chat/data/theme/color/color_base.dart';
import 'package:tencent_cloud_chat/data/theme/text_style/text_style.dart';
import 'package:tencent_cloud_chat/tencent_cloud_chat.dart';
import 'package:tencent_cloud_chat/utils/tencent_cloud_chat_code_info.dart';
import 'package:tencent_cloud_chat/utils/tencent_cloud_chat_utils.dart';
import 'package:tencent_cloud_chat_common/base/tencent_cloud_chat_state_widget.dart';
import 'package:tencent_cloud_chat_common/base/tencent_cloud_chat_theme_widget.dart';
import 'package:tencent_cloud_chat_message/data/tencent_cloud_chat_message_separate_data.dart';
import 'package:tencent_cloud_chat_message/data/tencent_cloud_chat_message_separate_data_notifier.dart';
import 'package:tencent_cloud_chat_message/tencent_cloud_chat_message_widgets/menu/tencent_cloud_chat_message_item_with_menu_container.dart';
import 'package:tencent_cloud_chat_message/tencent_cloud_chat_message_widgets/tencent_cloud_chat_message_item_container.dart';

class TencentCloudChatMessageRowContainer extends StatefulWidget {
  final V2TimMessage message;
  final bool inMergerMessagePreviewMode;
  final double messageRowWidth;

  const TencentCloudChatMessageRowContainer({
    super.key,
    required this.message,
    required this.inMergerMessagePreviewMode,
    required this.messageRowWidth,
  });

  @override
  State<TencentCloudChatMessageRowContainer> createState() => _TencentCloudChatMessageRowContainerState();
}

class _TencentCloudChatMessageRowContainerState extends TencentCloudChatState<TencentCloudChatMessageRowContainer> {
  late TencentCloudChatMessageSeparateDataProvider dataProvider;

  final Stream<TencentCloudChatMessageData<dynamic>>? _messageDataStream =
      TencentCloudChat.instance.eventBusInstance.on<TencentCloudChatMessageData>("TencentCloudChatMessageData");
  late StreamSubscription<TencentCloudChatMessageData<dynamic>>? _messageDataSubscription;

  bool _isSelected = false;
  bool _inSelectMode = false;

  late V2TimMessage _message;

  bool _needTranslate = false;
  bool _needSoundToText = false;

  @override
  void initState() {
    super.initState();
    _message = widget.message;
    _messageDataSubscription = _messageDataStream?.listen(_messageDataHandler);
  }

  @override
  void didUpdateWidget(covariant TencentCloudChatMessageRowContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.message != _message && widget.message != oldWidget.message) {
      _message = widget.message;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    dataProvider = TencentCloudChatMessageDataProviderInherited.of(context);
    dataProvider.addListener(dataProviderListener);
    dataProviderListener();
  }

  @override
  void dispose() {
    super.dispose();
    dataProvider.removeListener(dataProviderListener);
    _messageDataSubscription?.cancel();
  }

  // This method handles changes in message data.
  void _messageDataHandler(TencentCloudChatMessageData messageData) {
    final msgID = _message.msgID;
    final TencentCloudChatMessageDataKeys messageDataKeys = messageData.currentUpdatedFields;

    switch (messageDataKeys) {
      case TencentCloudChatMessageDataKeys.messageNeedUpdate:
        if (TencentCloudChat.instance.dataInstance.messageData.messageNeedUpdate != null &&
            msgID == TencentCloudChat.instance.dataInstance.messageData.messageNeedUpdate?.msgID &&
            TencentCloudChatUtils.checkString(msgID) != null) {
          safeSetState(() {
            _message = TencentCloudChat.instance.dataInstance.messageData.messageNeedUpdate!;
          });
        }
        break;
      default:
        break;
    }
  }

  void dataProviderListener() {
    /// _isSelected
    final selectMessages = dataProvider.selectedMessages;
    final translatedTextMessages = dataProvider.translatedMessages;
    final soundToTextMessages = dataProvider.soundToTextMessages;

    final newSelected = selectMessages.any((element) =>
        (TencentCloudChatUtils.checkString(_message.msgID) != null && element.msgID == _message.msgID) ||
        (TencentCloudChatUtils.checkString(_message.id) != null && element.id == _message.id));

    final needTranslated = translatedTextMessages.any((element) =>
        (TencentCloudChatUtils.checkString(_message.msgID) != null && element.msgID == _message.msgID) ||
        (TencentCloudChatUtils.checkString(_message.id) != null && element.id == _message.id));

    final needSoundToText = soundToTextMessages.any((element) =>
        (TencentCloudChatUtils.checkString(_message.msgID) != null && element.msgID == _message.msgID) ||
        (TencentCloudChatUtils.checkString(_message.id) != null && element.id == _message.id));

    if (newSelected != _isSelected) {
      safeSetState(() {
        _isSelected = newSelected;
      });
    }

    /// _inSelectMode
    final inSelectMode = dataProvider.inSelectMode;
    if (_inSelectMode != inSelectMode) {
      safeSetState(() {
        _inSelectMode = inSelectMode;
      });
    }

    if (needTranslated && dataProvider.textTranslatePluginInstance != null) {
      safeSetState(() {
        _needTranslate = needTranslated;
      });
    }

    if (needSoundToText && dataProvider.soundToTextPluginInstance != null) {
      safeSetState(() {
        _needSoundToText = needSoundToText;
      });
    }
  }

  Widget? _getTextTranslatedMessageWidget(TencentCloudChatThemeColors colorTheme, TencentCloudChatTextStyle textStyle) {
    if (_needTranslate) {
      final plugin = dataProvider.textTranslatePluginInstance as dynamic;
      final text = _message.textElem?.text;
      if (text != null) {
        final sentFromSelf = _message.isSelf ?? false;
        final padding = EdgeInsets.symmetric(horizontal: getWidth(10), vertical: getHeight(8));
        final decoration = BoxDecoration(
            color: (sentFromSelf ? colorTheme.selfMessageBubbleColor : colorTheme.othersMessageBubbleColor),
            border: Border.all(
              color: sentFromSelf ? colorTheme.selfMessageBubbleBorderColor : colorTheme.othersMessageBubbleBorderColor,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(5)));
        final translateTextStyle = TextStyle(
            color: sentFromSelf ? colorTheme.selfMessageTextColor : colorTheme.othersMessageTextColor,
            fontSize: textStyle.messageBody);
        final translateBoxStyle = {
          "boxDecoration": decoration,
          "boxPadding": padding,
          "translateTextStyle": translateTextStyle,
        };
        plugin.callMethodSync(methodName: "setTranslateBoxStyle", methodValue: translateBoxStyle);
        final targetLanguage = TencentCloudChatIntl().getCurrentLocale(context).languageCode;
        final widget = plugin.getWidgetSync(methodName: "getWidget", data: {
          "text": text,
          "targetLanguage": targetLanguage,
        });
        return widget;
      }
    }
    return null;
  }

  Widget? _getSoundToTextWidget(TencentCloudChatThemeColors colorTheme, TencentCloudChatTextStyle textStyle) {
    if (_needSoundToText) {
      final plugin = dataProvider.soundToTextPluginInstance as dynamic;
      final msgID = _message.msgID;
      if (msgID != null) {
        final sentFromSelf = _message.isSelf ?? false;
        final padding = EdgeInsets.symmetric(horizontal: getWidth(10), vertical: getHeight(8));
        final decoration = BoxDecoration(
            color: (sentFromSelf ? colorTheme.selfMessageBubbleColor : colorTheme.othersMessageBubbleColor),
            border: Border.all(
              color: sentFromSelf ? colorTheme.selfMessageBubbleBorderColor : colorTheme.othersMessageBubbleBorderColor,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(5)));
        final translateTextStyle = TextStyle(
            color: sentFromSelf ? colorTheme.selfMessageTextColor : colorTheme.othersMessageTextColor,
            fontSize: textStyle.messageBody);
        final translateBoxStyle = {
          "boxDecoration": decoration,
          "boxPadding": padding,
          "translateTextStyle": translateTextStyle,
        };
        plugin.callMethodSync(methodName: "setTranslateBoxStyle", methodValue: translateBoxStyle);
        final widget = plugin.getWidgetSync(methodName: "getWidget", data: {
          "msgID": msgID,
          "language": ""
        });
        return widget;
      }
    }
    return null;
  }

  bool _checkTranslateEnable() {
    if (dataProvider.textTranslatePluginInstance != null) {
      final plugin = dataProvider.textTranslatePluginInstance as dynamic;
      final topicID = dataProvider.topicID;
      final groupID = dataProvider.groupID;
      final userID = _message.sender;
      final text = _message.textElem?.text;
      final methodValue = {
        "groupID": groupID,
        "topicID": topicID,
        "userID": userID,
        "message": text,
      };
      final result = plugin.callMethodSync(methodName: "checkTranslateEnable", methodValue: methodValue);
      return result["enable"] ?? false;
    }
    return false;
  }

  @override
  Widget defaultBuilder(BuildContext context) {
    return TencentCloudChatThemeWidget(
      build: (context, colorTheme, textStyle) => TencentCloudChatMessageItemContainer(
        message: _message,
        messageRowWidth: widget.messageRowWidth,
        inMergerMessagePreviewMode: widget.inMergerMessagePreviewMode,
        messageBuilder: (
          ctx,
          bool shouldBeHighlighted,
          void Function() clearHighlightFunc,
          V2TimMessageReceipt? messageReceipt,
          String? text,
          SendingMessageData? sendingMessageData,
        ) {
          final messageReply =
              TencentCloudChatUtils.parseMessageReply(TencentCloudChatUtils.checkString(_message.cloudCustomData));
          final tipsItem = _message.elemType == 101 || _message.elemType == MessageElemType.V2TIM_ELEM_TYPE_GROUP_TIPS;
          final recalledMessage = _message.status == MessageStatus.V2TIM_MSG_STATUS_LOCAL_REVOKED;
          if (sendingMessageData?.message != null) {
            _message = sendingMessageData!.message;
          }
          final repliedMessageItem = (TencentCloudChatUtils.checkString(messageReply.messageID) != null)
              ? dataProvider.messageBuilders?.getMessageReplyViewBuilder(
                  data: MessageReplyViewBuilderData(
                    messageSender: messageReply.messageSender,
                    messageAbstract: messageReply.messageAbstract,
                    messageID: messageReply.messageID!,
                    messageSeq: messageReply.messageSeq,
                    messageTimestamp: messageReply.messageTimestamp,
                  ),
                  methods: MessageReplyViewBuilderMethods(
                    onTriggerNavigation: () async {
                      final res = await dataProvider.loadToSpecificMessage(
                          highLightTargetMessage: true,
                          message: V2TimMessage(
                            msgID: messageReply.messageID,
                            elemType: 0,
                            timestamp: messageReply.messageTimestamp,
                            seq: messageReply.messageSeq?.toString(),
                          ));
                      if (!res) {
                        TencentCloudChat.instance.callbacks.onUserNotificationEvent(
                          TencentCloudChatComponentsEnum.message,
                          TencentCloudChatCodeInfo.originalMessageNotFound,
                        );
                      }
                    },
                  ),
                )
              : null;
          return dataProvider.messageBuilders?.getMessageRowBuilder(
                key: Key(_message.msgID ?? _message.id!),
                data: MessageRowBuilderData(
                  message: _message,
                  userID: dataProvider.userID,
                  topicID: dataProvider.topicID,
                  groupID: dataProvider.groupID,
                  messageRowWidth: widget.messageRowWidth,
                  inSelectMode: _inSelectMode,
                  showSelfAvatar: dataProvider.config.showSelfAvatar(
                    userID: dataProvider.userID,
                    groupID: dataProvider.groupID,
                    topicID: dataProvider.topicID,
                  ),
                  showMessageSenderName: dataProvider.config.showMessageSenderName(
                    userID: dataProvider.userID,
                    groupID: dataProvider.groupID,
                    topicID: dataProvider.topicID,
                  ),
                  showOthersAvatar: dataProvider.config.showOthersAvatar(
                    userID: dataProvider.userID,
                    groupID: dataProvider.groupID,
                    topicID: dataProvider.topicID,
                  ),
                  showMessageTimeIndicator: dataProvider.config.showMessageTimeIndicator(
                    userID: dataProvider.userID,
                    topicID: dataProvider.topicID,
                    groupID: dataProvider.groupID,
                  ),
                  showMessageStatusIndicator: dataProvider.config.showMessageStatusIndicator(
                    userID: dataProvider.userID,
                    groupID: dataProvider.groupID,
                    topicID: dataProvider.topicID,
                  ),
                  isSelected: _isSelected,
                  isMergeMessage: widget.inMergerMessagePreviewMode,
                  hasStickerPlugin: dataProvider.hasStickerPlugin,
                  stickerPluginInstance: dataProvider.stickerPluginInstance,
                ),
                methods: MessageRowBuilderMethods(
                    onSelectCurrent: (msg) {
                      final selectMessages = dataProvider.selectedMessages;
                      if (selectMessages.any((element) =>
                          (TencentCloudChatUtils.checkString(msg.msgID) != null && element.msgID == msg.msgID) ||
                          (TencentCloudChatUtils.checkString(msg.id) != null && element.id == msg.id))) {
                        selectMessages.removeWhere((element) =>
                            (TencentCloudChatUtils.checkString(msg.msgID) != null && element.msgID == msg.msgID) ||
                            (TencentCloudChatUtils.checkString(msg.id) != null && element.id == msg.id));
                      } else {
                        selectMessages.add(msg);
                      }
                      dataProvider.selectedMessages = selectMessages;
                    },
                    loadToSpecificMessage: dataProvider.loadToSpecificMessage),
                widgets: MessageRowBuilderWidgets(
                  messageTextTransalteItem: _getTextTranslatedMessageWidget(colorTheme, textStyle),
                  messageSoundToTextItem: _getSoundToTextWidget(colorTheme, textStyle),
                  messageRowAvatar: dataProvider.messageBuilders?.getMessageRowMessageSenderAvatarBuilder(
                          data: MessageRowMessageSenderAvatarBuilderData(
                            message: _message,
                            userID: dataProvider.userID,
                            groupID: dataProvider.groupID,
                            topicID: dataProvider.topicID,
                            messageSenderAvatarURL: _message.faceUrl ?? "",
                          ),
                          methods: MessageRowMessageSenderAvatarBuilderMethods(
                            onCustomUIEventPrimaryTapAvatar:
                                dataProvider.messageEventHandlers?.uiEventHandlers.onPrimaryTapAvatar,
                            onCustomUIEventSecondaryTapAvatar:
                                dataProvider.messageEventHandlers?.uiEventHandlers.onSecondaryTapAvatar,
                          )) ??
                      Container(),
                  messageRowMessageSenderName: dataProvider.messageBuilders?.getMessageRowMessageSenderNameBuilder(
                        data: MessageRowMessageSenderNameBuilderData(
                          message: _message,
                          userID: dataProvider.userID,
                          groupID: dataProvider.groupID,
                          topicID: dataProvider.topicID,
                          messageSenderName: TencentCloudChatUtils.getMessageSenderName(_message),
                        ),
                        methods: MessageRowMessageSenderNameBuilderMethods(),
                      ) ??
                      Container(),
                  messageReplyItem: repliedMessageItem,
                  messageRowTips: (recalledMessage || tipsItem)
                      ? dataProvider.messageBuilders?.getMessageItemBuilder(
                            key: ((TencentCloudChatUtils.checkString(_message.msgID) ?? _message.id) != null)
                                ? Key((TencentCloudChatUtils.checkString(_message.msgID) ?? _message.id)!)
                                : null,
                            data: MessageItemBuilderData(
                              message: _message,
                              userID: dataProvider.userID,
                              topicID: dataProvider.topicID,
                              groupID: dataProvider.groupID,
                              renderOnMenuPreview: false,
                              inSelectMode: dataProvider.inSelectMode,
                              shouldBeHighlighted: shouldBeHighlighted,
                              repliedMessageItem: repliedMessageItem,
                              enableParseMarkdown: dataProvider.config.enableParseMarkdown(
                                userID: dataProvider.userID,
                                groupID: dataProvider.groupID,
                                topicID: dataProvider.topicID,
                              ),
                              showMessageSenderName: dataProvider.config.showMessageSenderName(
                                userID: dataProvider.userID,
                                groupID: dataProvider.groupID,
                                topicID: dataProvider.topicID,
                              ),
                              showMessageStatusIndicator: dataProvider.config.showMessageStatusIndicator(
                                userID: dataProvider.userID,
                                groupID: dataProvider.groupID,
                                topicID: dataProvider.topicID,
                              ),
                              showMessageTimeIndicator: dataProvider.config.showMessageTimeIndicator(
                                userID: dataProvider.userID,
                                groupID: dataProvider.groupID,
                                topicID: dataProvider.topicID,
                              ),
                              messageReceipt: messageReceipt,
                              messageRowWidth: widget.messageRowWidth,
                              sendingMessageData: sendingMessageData,
                              inMergerMessagePreviewMode: widget.inMergerMessagePreviewMode,
                              altText: text ?? "[${tL10n.message}]",
                              hasStickerPlugin: dataProvider.hasStickerPlugin,
                              stickerPluginInstance: dataProvider.stickerPluginInstance,
                              messageReactionPluginInstance: dataProvider.messageReactionPluginInstance,
                            ),
                            methods: MessageItemBuilderMethods(
                              clearHighlightFunc: clearHighlightFunc,
                              setMessageTextWithMentions: (
                                      {required List<String> groupMembersNeedToMention, required String messageText}) =>
                                  dataProvider.messageController.setMessageTextWithMentions(
                                messageText: messageText,
                                groupMembersToMention: groupMembersNeedToMention.map((member) {
                                  final target = dataProvider.groupMemberList
                                      .firstWhere((element) => element?.userID == member, orElse: () => null);
                                  return target ??
                                      V2TimGroupMemberFullInfo(
                                        userID: member,
                                      );
                                }).toList(),
                                user: dataProvider.userID,
                                group: dataProvider.groupID,
                                topicID: dataProvider.topicID,
                              ),
                              triggerLinkTappedEvent: dataProvider.triggerLinkTappedEvent,
                              onSelectMessage: () => (msg) {
                                final selectMessages = dataProvider.selectedMessages;
                                if (selectMessages.any((element) =>
                                    (TencentCloudChatUtils.checkString(msg.msgID) != null &&
                                        element.msgID == msg.msgID) ||
                                    (TencentCloudChatUtils.checkString(msg.id) != null && element.id == msg.id))) {
                                  selectMessages.removeWhere((element) =>
                                      (TencentCloudChatUtils.checkString(msg.msgID) != null &&
                                          element.msgID == msg.msgID) ||
                                      (TencentCloudChatUtils.checkString(msg.id) != null && element.id == msg.id));
                                } else {
                                  selectMessages.add(msg);
                                }
                                dataProvider.selectedMessages = selectMessages;
                              },
                            ),
                          ) ??
                          Container()
                      : null,
                  messageRowMessageItem: TencentCloudChatMessageItemWithMenuContainer(
                    isTextTranslatePluginEnabled: _checkTranslateEnable(),
                    useMessageReaction: dataProvider.messageReactionPluginInstance != null,
                    isSoundToTextPluginEnabled: dataProvider.soundToTextPluginInstance != null,
                    message: _message,
                    isMergeMessage: widget.inMergerMessagePreviewMode,
                    getMessageItemWidget: ({required bool renderOnMenuPreview, Key? key}) {
                      return dataProvider.messageBuilders?.getMessageItemBuilder(
                            key: key,
                            data: MessageItemBuilderData(
                              message: _message,
                              userID: dataProvider.userID,
                              topicID: dataProvider.topicID,
                              messageReactionPluginInstance: dataProvider.messageReactionPluginInstance,
                              repliedMessageItem: repliedMessageItem,
                              groupID: dataProvider.groupID,
                              renderOnMenuPreview: renderOnMenuPreview,
                              enableParseMarkdown: dataProvider.config.enableParseMarkdown(
                                userID: dataProvider.userID,
                                groupID: dataProvider.groupID,
                                topicID: dataProvider.topicID,
                              ),
                              showMessageSenderName: dataProvider.config.showMessageSenderName(
                                userID: dataProvider.userID,
                                groupID: dataProvider.groupID,
                                topicID: dataProvider.topicID,
                              ),
                              inSelectMode: dataProvider.inSelectMode,
                              shouldBeHighlighted: shouldBeHighlighted,
                              showMessageStatusIndicator: dataProvider.config.showMessageStatusIndicator(
                                userID: dataProvider.userID,
                                groupID: dataProvider.groupID,
                                topicID: dataProvider.topicID,
                              ),
                              showMessageTimeIndicator: dataProvider.config.showMessageTimeIndicator(
                                userID: dataProvider.userID,
                                groupID: dataProvider.groupID,
                                topicID: dataProvider.topicID,
                              ),
                              messageReceipt: messageReceipt,
                              messageRowWidth: widget.messageRowWidth,
                              sendingMessageData: sendingMessageData,
                              altText: text ?? "[${tL10n.message}]",
                              inMergerMessagePreviewMode: widget.inMergerMessagePreviewMode,
                              hasStickerPlugin: dataProvider.hasStickerPlugin,
                              stickerPluginInstance: dataProvider.stickerPluginInstance,
                            ),
                            methods: MessageItemBuilderMethods(
                              clearHighlightFunc: clearHighlightFunc,
                              triggerLinkTappedEvent: dataProvider.triggerLinkTappedEvent,
                              setMessageTextWithMentions: (
                                      {required List<String> groupMembersNeedToMention, required String messageText}) =>
                                  dataProvider.messageController.setMessageTextWithMentions(
                                messageText: messageText,
                                groupMembersToMention: groupMembersNeedToMention.map((member) {
                                  final target = dataProvider.groupMemberList
                                      .firstWhere((element) => element?.userID == member, orElse: () => null);
                                  return target ??
                                      V2TimGroupMemberFullInfo(
                                        userID: member,
                                      );
                                }).toList(),
                                user: dataProvider.userID,
                                group: dataProvider.groupID,
                                topicID: dataProvider.topicID,
                              ),
                              onSelectMessage: () => (msg) {
                                final selectMessages = dataProvider.selectedMessages;
                                if (selectMessages.any((element) =>
                                    (TencentCloudChatUtils.checkString(msg.msgID) != null &&
                                        element.msgID == msg.msgID) ||
                                    (TencentCloudChatUtils.checkString(msg.id) != null && element.id == msg.id))) {
                                  selectMessages.removeWhere((element) =>
                                      (TencentCloudChatUtils.checkString(msg.msgID) != null &&
                                          element.msgID == msg.msgID) ||
                                      (TencentCloudChatUtils.checkString(msg.id) != null && element.id == msg.id));
                                } else {
                                  selectMessages.add(msg);
                                }
                                dataProvider.selectedMessages = selectMessages;
                              },
                            ),
                          ) ??
                          Container();
                    },
                  ),
                ),
              ) ??
              Container();
        },
      ),
    );
  }
}
