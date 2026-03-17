import 'dart:io';

const mapping = {
  'arrow_back_ios_new_rounded': 'arrowLeft', 'arrow_back_ios_new': 'arrowLeft',
  'arrow_back_ios_rounded': 'arrowLeft', 'arrow_back_ios': 'arrowLeft',
  'arrow_back_rounded': 'arrowLeft', 'arrow_back': 'arrowLeft',
  'arrow_forward_ios_rounded': 'arrowRight', 'arrow_forward_ios': 'arrowRight',
  'arrow_forward_rounded': 'arrowRight', 'arrow_forward': 'arrowRight',
  'arrow_upward_rounded': 'arrowUp', 'arrow_upward': 'arrowUp',
  'arrow_downward_rounded': 'arrowDown', 'arrow_downward': 'arrowDown',
  'chevron_right_rounded': 'chevronRight', 'chevron_right': 'chevronRight',
  'chevron_left_rounded': 'chevronLeft', 'chevron_left': 'chevronLeft',
  'keyboard_arrow_right': 'chevronRight', 'keyboard_arrow_left': 'chevronLeft',
  'keyboard_arrow_down': 'chevronDown', 'keyboard_arrow_up': 'chevronUp',
  'expand_more_rounded': 'chevronDown', 'expand_more': 'chevronDown',
  'expand_less_rounded': 'chevronUp', 'expand_less': 'chevronUp',
  'close_rounded': 'xmark', 'close': 'xmark',
  'clear_rounded': 'xmark', 'clear': 'xmark',
  'cancel_rounded': 'xmark', 'cancel': 'xmark',
  'done_all_rounded': 'checkDouble', 'done_all': 'checkDouble',
  'done_rounded': 'check', 'done': 'check',
  'check_circle_outline_rounded': 'circleCheck', 'check_circle_outline': 'circleCheck',
  'check_circle_rounded': 'solidCircleCheck', 'check_circle': 'solidCircleCheck',
  'task_alt_rounded': 'circleCheck', 'task_alt': 'circleCheck',
  'check_rounded': 'check', 'check': 'check',
  'error_outline_rounded': 'circleExclamation', 'error_outline': 'circleExclamation',
  'error_rounded': 'circleExclamation', 'error': 'circleExclamation',
  'warning_amber_rounded': 'triangleExclamation', 'warning_amber': 'triangleExclamation',
  'warning_rounded': 'triangleExclamation', 'warning': 'triangleExclamation',
  'info_outline_rounded': 'circleInfo', 'info_outline': 'circleInfo',
  'info_rounded': 'circleInfo', 'info': 'circleInfo',
  'help_outline_rounded': 'circleQuestion', 'help_outline': 'circleQuestion',
  'help_rounded': 'circleQuestion', 'help': 'circleQuestion',
  'contact_support_rounded': 'headset', 'contact_support': 'headset',
  'support_agent_rounded': 'headset', 'support_agent': 'headset',
  'add_circle_outline_rounded': 'circlePlus', 'add_circle_outline': 'circlePlus',
  'add_circle_rounded': 'solidCirclePlus', 'add_circle': 'solidCirclePlus',
  'add_rounded': 'plus', 'add': 'plus',
  'remove_rounded': 'minus', 'remove': 'minus',
  'more_vert_rounded': 'ellipsisVertical', 'more_vert': 'ellipsisVertical',
  'more_horiz_rounded': 'ellipsis', 'more_horiz': 'ellipsis',
  'edit_rounded': 'penToSquare', 'edit': 'penToSquare',
  'mode_edit_rounded': 'penToSquare', 'mode_edit': 'penToSquare',
  'delete_outline_rounded': 'trash', 'delete_outline': 'trash',
  'delete_rounded': 'trash', 'delete': 'trash',
  'content_copy_rounded': 'copy', 'content_copy': 'copy',
  'share_rounded': 'shareNodes', 'share': 'shareNodes',
  'refresh_rounded': 'arrowsRotate', 'refresh': 'arrowsRotate',
  'replay_rounded': 'arrowsRotate', 'replay': 'arrowsRotate',
  'filter_list_rounded': 'filter', 'filter_list': 'filter',
  'filter_alt_rounded': 'filter', 'filter_alt': 'filter',
  'tune_rounded': 'sliders', 'tune': 'sliders',
  'open_in_new_rounded': 'arrowUpRightFromSquare', 'open_in_new': 'arrowUpRightFromSquare',
  'attach_file_rounded': 'paperclip', 'attach_file': 'paperclip',
  'upload_file_rounded': 'upload', 'upload_file': 'upload',
  'file_upload_rounded': 'upload', 'file_upload': 'upload',
  'download_rounded': 'download', 'download': 'download',
  'send_rounded': 'paperPlane', 'send': 'paperPlane',
  'reply_rounded': 'reply', 'reply': 'reply',
  'block_rounded': 'ban', 'block': 'ban',
  'flag_rounded': 'flag', 'flag': 'flag',
  'home_outlined': 'house', 'home_rounded': 'house', 'home': 'house',
  'search_outlined': 'magnifyingGlass', 'search_rounded': 'magnifyingGlass', 'search': 'magnifyingGlass',
  'person_outline_rounded': 'user', 'person_outline': 'user',
  'person_rounded': 'solidUser', 'person_add_rounded': 'userPlus', 'person_add': 'userPlus',
  'person_remove_rounded': 'userMinus', 'person_remove': 'userMinus', 'person': 'user',
  'account_circle_rounded': 'circleUser', 'account_circle': 'circleUser',
  'manage_accounts_rounded': 'userGear', 'manage_accounts': 'userGear',
  'badge_rounded': 'idBadge', 'badge': 'idBadge',
  'group_rounded': 'users', 'group': 'users',
  'people_rounded': 'users', 'people': 'users',
  'notifications_active_rounded': 'solidBell', 'notifications_active': 'solidBell',
  'notifications_none_rounded': 'bell', 'notifications_none': 'bell',
  'notifications_outlined': 'bell', 'notifications_rounded': 'solidBell', 'notifications': 'solidBell',
  'favorite_outline_rounded': 'heart', 'favorite_border_rounded': 'heart',
  'favorite_border': 'heart', 'favorite_outline': 'heart',
  'favorite_rounded': 'solidHeart', 'favorite': 'solidHeart',
  'star_outline_rounded': 'star', 'star_outline': 'star',
  'star_border_rounded': 'star', 'star_border': 'star',
  'stars_rounded': 'solidStar', 'stars': 'solidStar',
  'star_rounded': 'solidStar', 'star': 'solidStar',
  'bookmark_border_rounded': 'bookmark', 'bookmark_border': 'bookmark',
  'bookmark_rounded': 'solidBookmark', 'bookmark': 'solidBookmark',
  'thumb_up_rounded': 'thumbsUp', 'thumb_up': 'thumbsUp',
  'thumb_down_rounded': 'thumbsDown', 'thumb_down': 'thumbsDown',
  'shopping_cart_outlined': 'cartShopping', 'shopping_cart_rounded': 'cartShopping', 'shopping_cart': 'cartShopping',
  'shopping_bag_outlined': 'bagShopping', 'shopping_bag_rounded': 'bagShopping', 'shopping_bag': 'bagShopping',
  'storefront_outlined': 'store', 'storefront_rounded': 'store', 'storefront': 'store',
  'store_outlined': 'store', 'store_rounded': 'store', 'store': 'store',
  'card_giftcard_rounded': 'gift', 'card_giftcard': 'gift',
  'credit_card_rounded': 'creditCard', 'credit_card': 'creditCard',
  'payments_outlined': 'moneyBill', 'payments_rounded': 'moneyBill', 'payments': 'moneyBill',
  'payment_rounded': 'creditCard', 'payment': 'creditCard',
  'attach_money_rounded': 'dollarSign', 'attach_money': 'dollarSign',
  'monetization_on_rounded': 'dollarSign', 'monetization_on': 'dollarSign',
  'receipt_long_outlined': 'receipt', 'receipt_long_rounded': 'receipt', 'receipt_long': 'receipt',
  'receipt_rounded': 'receipt', 'receipt': 'receipt',
  'local_shipping_outlined': 'truck', 'local_shipping_rounded': 'truck', 'local_shipping': 'truck',
  'delivery_dining_rounded': 'truckFast', 'delivery_dining': 'truckFast',
  'inventory_2_rounded': 'boxOpen', 'inventory_2': 'boxOpen',
  'inventory_rounded': 'boxOpen', 'inventory': 'boxOpen',
  'card_membership_rounded': 'idCard', 'card_membership': 'idCard',
  'loyalty_rounded': 'award', 'loyalty': 'award',
  'local_offer_rounded': 'tag', 'local_offer': 'tag',
  'sell_rounded': 'tag', 'sell': 'tag',
  'discount_rounded': 'tag', 'discount': 'tag',
  'label_rounded': 'tag', 'label': 'tag',
  'tag_rounded': 'tag', 'tag': 'tag',
  'percent_rounded': 'percent', 'percent': 'percent',
  'lock_open_outline_rounded': 'lockOpen', 'lock_open_rounded': 'lockOpen', 'lock_open': 'lockOpen',
  'lock_outline_rounded': 'lock', 'lock_outline': 'lock', 'lock_rounded': 'lock', 'lock': 'lock',
  'visibility_off_outlined': 'eyeSlash', 'visibility_off_rounded': 'eyeSlash', 'visibility_off': 'eyeSlash',
  'visibility_outlined': 'eye', 'visibility_rounded': 'eye', 'visibility': 'eye',
  'security_rounded': 'shield', 'security': 'shield',
  'verified_user_rounded': 'shieldHalved', 'verified_user': 'shieldHalved',
  'verified_rounded': 'shieldHalved', 'verified': 'shieldHalved',
  'key_rounded': 'key', 'key': 'key',
  'password_rounded': 'key', 'password': 'key',
  'fingerprint_rounded': 'fingerprint', 'fingerprint': 'fingerprint',
  'settings_rounded': 'gear', 'settings': 'gear',
  'logout_rounded': 'rightFromBracket', 'logout': 'rightFromBracket',
  'exit_to_app_rounded': 'rightFromBracket', 'exit_to_app': 'rightFromBracket',
  'login_rounded': 'rightToBracket', 'login': 'rightToBracket',
  'email_outlined': 'envelope', 'email_rounded': 'envelope', 'email': 'envelope',
  'mail_outline_rounded': 'envelope', 'mail_outline': 'envelope',
  'mail_rounded': 'solidEnvelope', 'mail': 'envelope',
  'phone_android_rounded': 'mobileScreen', 'phone_android': 'mobileScreen',
  'phone_iphone_rounded': 'mobileScreen', 'phone_iphone': 'mobileScreen',
  'phone_outlined': 'phone', 'phone_rounded': 'phone', 'phone': 'phone',
  'location_on_rounded': 'locationDot', 'location_on_outlined': 'locationDot', 'location_on': 'locationDot',
  'place_rounded': 'locationDot', 'place': 'locationDot',
  'map_rounded': 'map', 'map': 'map',
  'language_rounded': 'globe', 'language': 'globe',
  'public_rounded': 'globe', 'public': 'globe',
  'link_rounded': 'link', 'link': 'link',
  'contacts_rounded': 'addressBook', 'contacts': 'addressBook',
  'contact_page_rounded': 'addressBook', 'contact_page': 'addressBook',
  'inbox_rounded': 'inbox', 'inbox': 'inbox',
  'drafts_rounded': 'envelopeOpen', 'drafts': 'envelopeOpen',
  'camera_alt_rounded': 'camera', 'camera_alt': 'camera',
  'camera_rounded': 'camera', 'camera': 'camera',
  'photo_camera_rounded': 'camera', 'photo_camera': 'camera',
  'image_search_rounded': 'magnifyingGlass', 'image_search': 'magnifyingGlass',
  'image_rounded': 'image', 'image': 'image',
  'photo_outlined': 'image', 'photo_rounded': 'image', 'photo': 'image',
  'qr_code_scanner_rounded': 'qrcode', 'qr_code_scanner': 'qrcode',
  'qr_code_2_rounded': 'qrcode', 'qr_code_2': 'qrcode',
  'qr_code_rounded': 'qrcode', 'qr_code': 'qrcode',
  'calendar_today_rounded': 'calendarDay', 'calendar_today': 'calendarDay',
  'date_range_rounded': 'calendarDays', 'date_range': 'calendarDays',
  'event_rounded': 'calendarDays', 'event': 'calendarDays',
  'access_time_rounded': 'clock', 'access_time': 'clock',
  'schedule_rounded': 'clock', 'schedule': 'clock',
  'timer_rounded': 'clock', 'timer': 'clock',
  'hourglass_empty_rounded': 'hourglassEmpty', 'hourglass_empty': 'hourglassEmpty',
  'hourglass_full_rounded': 'hourglass', 'hourglass_full': 'hourglass',
  'pending_rounded': 'hourglassHalf', 'pending': 'hourglassHalf',
  'bar_chart_rounded': 'chartBar', 'bar_chart': 'chartBar',
  'analytics_rounded': 'chartBar', 'analytics': 'chartBar',
  'trending_up_rounded': 'arrowTrendUp', 'trending_up': 'arrowTrendUp',
  'trending_down_rounded': 'arrowTrendDown', 'trending_down': 'arrowTrendDown',
  'dashboard_rounded': 'tableCells', 'dashboard': 'tableCells',
  'category_rounded': 'layerGroup', 'category': 'layerGroup',
  'list_alt_rounded': 'listUl', 'list_alt': 'listUl',
  'format_list_bulleted_rounded': 'listUl', 'format_list_bulleted': 'listUl',
  'list_rounded': 'listUl', 'list': 'listUl',
  'assignment_rounded': 'clipboardList', 'assignment': 'clipboardList',
  'auto_awesome_rounded': 'wandMagicSparkles', 'auto_awesome': 'wandMagicSparkles',
  'new_releases_rounded': 'certificate', 'new_releases': 'certificate',
  'flash_on_rounded': 'bolt', 'flash_on': 'bolt',
  'speed_rounded': 'gaugeHigh', 'speed': 'gaugeHigh',
  'radio_button_unchecked_rounded': 'circle', 'radio_button_unchecked': 'circle',
  'radio_button_checked_rounded': 'solidCircle', 'radio_button_checked': 'solidCircle',
  'sentiment_satisfied_rounded': 'faceSmile', 'sentiment_satisfied': 'faceSmile',
  'sentiment_dissatisfied_rounded': 'faceFrown', 'sentiment_dissatisfied': 'faceFrown',
  'emoji_emotions_rounded': 'faceSmile', 'emoji_emotions': 'faceSmile',
  'face_rounded': 'faceSmile', 'face': 'faceSmile',
};

const faImport = "import 'package:font_awesome_flutter/font_awesome_flutter.dart';";
const materialImport = "import 'package:flutter/material.dart';";

void main() {
  final libDir = Directory('lib');
  final dartFiles = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  // Sort keys by length descending to avoid partial replacements
  final sortedKeys = mapping.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));

  int changed = 0;
  int total = 0;

  for (final file in dartFiles) {
    String content;
    try {
      content = file.readAsStringSync();
    } catch (e) {
      continue;
    }
    if (!content.contains('Icons.')) continue;
    total++;

    final original = content;

    // Add FA import if not present
    if (!content.contains(faImport)) {
      content = content.replaceFirst(materialImport, '$materialImport\n$faImport');
    }

    // Replace icon names
    for (final matName in sortedKeys) {
      final faName = mapping[matName]!;
      content = content.replaceAll('Icons.$matName', 'FontAwesomeIcons.$faName');
    }

    // Replace Icon( → FaIcon( only where FontAwesomeIcons follows
    content = content.replaceAll('Icon(FontAwesomeIcons', 'FaIcon(FontAwesomeIcons');

    if (content != original) {
      file.writeAsStringSync(content);
      print('OK: ${file.path}');
      changed++;
    }
  }

  print('\nDone: $changed/$total files changed');
}
