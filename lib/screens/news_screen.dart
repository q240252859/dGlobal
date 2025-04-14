import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../providers/theme_provider.dart';
import '../providers/news_provider.dart';
import '../models/news_model.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({Key? key}) : super(key: key);

  @override
  _NewsScreenState createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  void _onRefresh(NewsProvider provider) async {
    await provider.refreshNews();
    _refreshController.refreshCompleted();
  }

  void _onLoading(NewsProvider provider) async {
    await provider.loadMoreNews();
    if (provider.hasMore) {
      _refreshController.loadComplete();
    } else {
      _refreshController.loadNoData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'News',
          style: TextStyle(
            color: theme.appBarTheme.titleTextStyle?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ChangeNotifierProvider<NewsProvider>(
        create: (_) => NewsProvider(),
        child: Consumer<NewsProvider>(
          builder: (context, provider, child) {
            return SmartRefresher(
              controller: _refreshController,
              enablePullDown: true,
              enablePullUp: provider.hasMore,
              header: const WaterDropHeader(),
              footer: CustomFooter(
                builder: (BuildContext context, LoadStatus? mode) {
                  Widget body;
                  if (mode == LoadStatus.idle) {
                    body = Text("pull up load");
                  } else if (mode == LoadStatus.loading) {
                    body = const CircularProgressIndicator();
                  } else if (mode == LoadStatus.failed) {
                    body = Text("Load Failed!Click retry!");
                  } else if (mode == LoadStatus.canLoading) {
                    body = Text("release to load more");
                  } else {
                    body = Text("No more Data");
                  }
                  return Container(
                    height: 55.0,
                    child: Center(child: body),
                  );
                },
              ),
              onRefresh: () => _onRefresh(provider),
              onLoading: () => _onLoading(provider),
              child: _buildBody(context, provider, theme),
            );
          },
        ),
      ),
    );
  }
}

Widget _buildBody(
    BuildContext context, NewsProvider provider, ThemeData theme) {
  if (provider.isLoading && provider.articles.isEmpty) {
    return const Center(child: CircularProgressIndicator());
  }

  if (provider.error != null && provider.articles.isEmpty) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(
            'Error: ${provider.error}',
            style: TextStyle(color: theme.colorScheme.error),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10.h),
          ElevatedButton(
            onPressed: () => provider.refreshNews(),
            child: Text('Retry'),
          )
        ]),
      ),
    );
  }

  if (provider.articles.isEmpty && !provider.isLoading) {
    return Center(
      child: Text(
        'No news available.',
        style: TextStyle(color: theme.textTheme.bodySmall?.color),
      ),
    );
  }

  return ListView.builder(
    itemCount: provider.articles.length,
    padding: EdgeInsets.symmetric(vertical: 8.h),
    itemBuilder: (context, index) {
      final article = provider.articles[index];
      return _buildNewsItem(context, article, theme);
    },
  );
}

Widget _buildNewsItem(
    BuildContext context, ArticleModel article, ThemeData theme) {
  return InkWell(
    onTap: () {
      Navigator.pushNamed(context, '/news_detail', arguments: article);
    },
    child: Container(
      margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (article.cover != null && article.cover!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4.r),
              child: CachedNetworkImage(
                imageUrl: article.cover!,
                placeholder: (context, url) => Container(
                  height: 150.h,
                  color: theme.highlightColor,
                  child:
                      Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 150.h,
                  color: theme.highlightColor,
                  child: Icon(Icons.broken_image,
                      color: theme.iconTheme.color?.withOpacity(0.5)),
                ),
                width: double.infinity,
                height: 150.h,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 12.h),
          ],
          Text(
            article.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
              color: theme.textTheme.titleMedium?.color,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4.h),
          Text(
            '${article.source.isNotEmpty ? article.source + " - " : "\n"}${article.publishTime}',
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
              fontSize: 12.sp,
            ),
          ),
          // if (article.content.isNotEmpty) ...[
          //   SizedBox(height: 8.h),
          //   Text(
          //     article.content,
          //     style: TextStyle(
          //       fontSize: 14.sp,
          //       color: theme.textTheme.bodyMedium?.color,
          //     ),
          //     maxLines: 3,
          //     overflow: TextOverflow.ellipsis,
          //   ),
          // ],
        ],
      ),
    ),
  );
}
