import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../widgets/app_shell.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({
    super.key,
    this.currentTabIndex,
    this.onTabSelected,
  });

  final int? currentTabIndex;
  final ValueChanged<int>? onTabSelected;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);

    return AppShell(
      title: '커뮤니티',
      modeName: controller.modeName,
      currentTabIndex: currentTabIndex,
      onTabSelected: onTabSelected,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '지역 여행 후기와 정산 팁',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '반값여행을 다녀온 사람들이 코스, 숙소, 정산 준비 경험을 공유하는 공간입니다.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ..._posts.map((item) => _CommunityPostCard(post: item)),
        ],
      ),
    );
  }
}

class _CommunityPostCard extends StatelessWidget {
  const _CommunityPostCard({required this.post});

  final _PreviewPost post;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  post.region,
                  style: const TextStyle(
                    color: Color(0xFF4338CA),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                post.meta,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF94A3B8),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            post.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            post.body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF475569),
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatChip(
                icon: Icons.favorite_border_rounded,
                label: '${post.likes}',
              ),
              const SizedBox(width: 10),
              _StatChip(
                icon: Icons.chat_bubble_outline_rounded,
                label: '${post.comments}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF475569),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _PreviewPost {
  const _PreviewPost({
    required this.region,
    required this.title,
    required this.body,
    required this.meta,
    required this.likes,
    required this.comments,
  });

  final String region;
  final String title;
  final String body;
  final String meta;
  final int likes;
  final int comments;
}

const List<_PreviewPost> _posts = [
  _PreviewPost(
    region: '완도',
    title: '전통시장 포함해서 하루 동선 짜는 법',
    body:
        '청해진 유적지에서 시작해서 해양치유센터, 전통시장까지 이어지도록 움직이면 인증과 식사 동선을 함께 맞추기 좋았습니다.',
    meta: '2시간 전',
    likes: 18,
    comments: 6,
  ),
  _PreviewPost(
    region: '영월',
    title: '숙박확인서 받을 때 미리 준비하면 좋은 항목',
    body:
        '대표자명, 전화번호, 주소를 먼저 메모해두면 현장에서 다시 확인하는 시간이 많이 줄어듭니다.',
    meta: '어제',
    likes: 12,
    comments: 4,
  ),
  _PreviewPost(
    region: '제천',
    title: '관광지 2곳 인증하고 영수증 정리한 방식 공유',
    body:
        '관광지 방문 순서대로 사진과 영수증을 정리해두면 정산 준비 화면에서 다시 찾을 일이 거의 없었습니다.',
    meta: '3일 전',
    likes: 21,
    comments: 9,
  ),
];
