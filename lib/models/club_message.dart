class ClubMessage {
  const ClubMessage({
    required this.sender,
    required this.text,
    required this.sentAt,
    this.isBot = false,
    this.isYou = false,
  });
  final String sender, text;
  final DateTime sentAt;
  final bool isBot, isYou;
}
