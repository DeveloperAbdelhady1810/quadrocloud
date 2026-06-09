class PublicClient {
  final int id;
  final String name;
  final String? company;
  final String? avatar;
  final int contractsCount;
  final int score;
  final int? rank;
  final bool isFollowing;
  final bool isMe;

  const PublicClient({
    required this.id,
    required this.name,
    this.company,
    this.avatar,
    required this.contractsCount,
    required this.score,
    this.rank,
    required this.isFollowing,
    required this.isMe,
  });

  factory PublicClient.fromJson(Map<String, dynamic> j) => PublicClient(
        id:             j['id'] as int,
        name:           j['public_name'] as String,
        company:        j['public_company'] as String?,
        avatar:         j['avatar'] as String?,
        contractsCount: j['contracts_count'] as int,
        score:          j['score'] as int,
        rank:           j['rank'] as int?,
        isFollowing:    j['is_following'] as bool,
        isMe:           j['is_me'] as bool,
      );

  PublicClient copyWith({bool? isFollowing}) => PublicClient(
        id:             id,
        name:           name,
        company:        company,
        avatar:         avatar,
        contractsCount: contractsCount,
        score:          score,
        rank:           rank,
        isFollowing:    isFollowing ?? this.isFollowing,
        isMe:           isMe,
      );
}

class LeaderboardEntry {
  final int clientId;
  final String displayName;
  final String? company;
  final String? avatar;
  final int score;
  final int rank;
  final String? medal; // 'gold' | 'silver' | 'bronze' | null
  final bool isGold;
  final bool isMe;
  final bool isFollowing;

  const LeaderboardEntry({
    required this.clientId,
    required this.displayName,
    this.company,
    this.avatar,
    required this.score,
    required this.rank,
    this.medal,
    required this.isGold,
    required this.isMe,
    required this.isFollowing,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) => LeaderboardEntry(
        clientId:    j['client_id'] as int,
        displayName: j['display_name'] as String,
        company:     j['company'] as String?,
        avatar:      j['avatar'] as String?,
        score:       j['score'] as int,
        rank:        j['rank'] as int,
        medal:       j['medal'] as String?,
        isGold:      j['is_gold'] as bool,
        isMe:        j['is_me'] as bool,
        isFollowing: j['is_following'] as bool,
      );
}

class LeaderboardData {
  final List<LeaderboardEntry> entries;
  final int? myRank;
  final int myScore;

  const LeaderboardData({required this.entries, this.myRank, required this.myScore});

  factory LeaderboardData.fromJson(Map<String, dynamic> j) => LeaderboardData(
        entries: (j['entries'] as List).map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>)).toList(),
        myRank:  j['my_rank'] as int?,
        myScore: j['my_score'] as int,
      );
}
