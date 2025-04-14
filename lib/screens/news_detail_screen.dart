import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/news_model.dart'; // Correct import now
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'package:flutter_html/flutter_html.dart'; // Import flutter_html

class NewsDetailScreen extends StatelessWidget {
  final ArticleModel article;

  const NewsDetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          article.title.isNotEmpty ? article.title : 'News Detail',
          style: TextStyle(color: theme.appBarTheme.titleTextStyle?.color),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        iconTheme: theme.appBarTheme.iconTheme,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              article.title,
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.titleLarge?.color,
              ),
            ),
            SizedBox(height: 8.h),
            // Publish Time / Source
            Text(
              '${article.source.isNotEmpty ? article.source + " - " : ""}${article.publishTime}',
              style: TextStyle(
                fontSize: 12.sp,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            SizedBox(height: 16.h),
            // Optional Cover Image
            if (article.cover != null && article.cover!.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: 16.h),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: CachedNetworkImage(
                    imageUrl: article.cover!,
                    placeholder: (context, url) => Container(
                      height: 200.h, // Placeholder height
                      color: theme.highlightColor,
                      child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 200.h,
                      color: theme.highlightColor,
                      child: Icon(Icons.broken_image,
                          color: theme.iconTheme.color?.withOpacity(0.5),
                          size: 50.sp),
                    ),
                    width: double.infinity,
                    height: 200.h,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            // Content
            // Option 2: HTML Content (Use flutter_html)
            Html(
              data: article.content, // Pass the HTML content
              style: {
                "body": Style(
                  fontSize: FontSize(15.sp),
                  color: theme.textTheme.bodyMedium?.color,
                  lineHeight: LineHeight(1.6),
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero,
                ),
                "p": Style(
                  margin: Margins.only(
                      bottom: 10.h), // Add margin between paragraphs
                  padding: HtmlPaddings.zero,
                ),
                // Add more styles for other HTML tags like h1, h2, a, img etc. as needed
                "a": Style(
                  color: theme.colorScheme.primary, // Use theme color for links
                  textDecoration: TextDecoration.none,
                ),
                // Add default styling for unstyled elements if needed
                "*": Style(
                  color: theme.textTheme.bodyMedium?.color,
                  fontSize: FontSize(15.sp),
                ),
              },
              // Optional: Handle link taps
              onLinkTap: (url, _, __) {
                if (url != null) {
                  // Handle opening the link (e.g., using url_launcher)
                  print('Tapped link: $url');
                  // launchUrl(Uri.parse(url)); // Requires url_launcher package
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
