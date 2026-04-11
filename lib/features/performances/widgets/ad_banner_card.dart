import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/services/api_service.dart';

class AdBannerCard extends StatelessWidget {
  final Map<String, dynamic> ad;
  const AdBannerCard({super.key, required this.ad});

  @override
  Widget build(BuildContext context) {
    final title = ad['title'] as String? ?? '';
    final imageUrl = ad['image_url'] as String?;
    final linkUrl = ad['link_url'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFF5F0E8),
        elevation: 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            if (linkUrl.isEmpty || !isAllowedBookingUrl(linkUrl)) return;
            final uri = Uri.tryParse(linkUrl);
            if (uri != null && await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          child: Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                if (imageUrl != null && imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                  ),
                if (imageUrl != null && imageUrl.isNotEmpty) const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4A843),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('AD',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text('Sponsored',
                          style: TextStyle(fontSize: 11, color: Color(0xFF999999))),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF999999)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
