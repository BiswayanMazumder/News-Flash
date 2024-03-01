import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class News {
  final String guid;
  final String link;
  final String pubDate;
  final String source;
  final String title;
  bool isSaved;

  News({
    required this.guid,
    required this.link,
    required this.pubDate,
    required this.source,
    required this.title,
    this.isSaved = false,
  });

  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      guid: json['guid'],
      link: json['link'],
      pubDate: json['pubDate'],
      source: json['source'],
      title: json['title'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'guid': guid,
      'link': link,
      'pubDate': pubDate,
      'source': source,
      'title': title,
    };
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NewsFlash!',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: NewsListPage(),
    );
  }
}

class NewsListPage extends StatefulWidget {
  @override
  _NewsListPageState createState() => _NewsListPageState();
}

class _NewsListPageState extends State<NewsListPage> {
  late List<News> _newsList;

  @override
  void initState() {
    super.initState();
    _newsList = [];
    fetchNews().then((newsList) {
      setState(() {
        _newsList = newsList;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: Text(
          'NewsFlash!',
          style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.bookmark,color: Colors.white,),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SavedNewsPage()),
              );
            },
          ),
        ],
      ),
      body: LiquidPullToRefresh(
        onRefresh: () async {
          // Fetch news
          List<News> newsList = await fetchNews();
          setState(() {
            _newsList = newsList;
          });
        },
        child: ListView.builder(
          itemCount: _newsList.length,
          itemBuilder: (context, index) {
            News news = _newsList[index];
            return NewsTile(news, () {
              setState(() {
                news.isSaved = !news.isSaved;
              });
              _saveOrRemoveNews(news);
            });
          },
        ),
      ),
    );
  }

  void _saveOrRemoveNews(News news) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedNews = prefs.getStringList('saved_news') ?? [];
    if (news.isSaved) {
      savedNews.add(jsonEncode(news.toJson()));
    } else {
      savedNews.removeWhere((element) {
        News savedNewsItem = News.fromJson(jsonDecode(element));
        return savedNewsItem.guid == news.guid;
      });
    }
    prefs.setStringList('saved_news', savedNews);
  }
}

class NewsTile extends StatelessWidget {
  final News news;
  final VoidCallback onPressed;

  NewsTile(this.news, this.onPressed);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ListTile(
        title: Column(
          children: [
            SizedBox(
              height: 20,
            ),
            Material(
              color: Colors.white,
              child: Container(
                color: Colors.grey,
                child: Center(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 20,
                      ),
                      Text(
                        news.title,
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        subtitle: Material(
          elevation: 20,
          shadowColor: Colors.white,
          color: Colors.white,
          child: Container(
            color: Colors.grey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      'Uploaded by ',
                      style: TextStyle(fontWeight: FontWeight.w300, color: Colors.black),
                    ),
                    Text(
                      '${news.source}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      'Uploaded on ',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.w300),
                    ),
                    Text(
                      '${news.pubDate}',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                    Spacer(),
                    IconButton(
                      onPressed: onPressed,
                      icon: Icon(
                        news.isSaved ? Icons.bookmark : Icons.bookmark_outline,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => NewsWebView(news.link)),
          );
        },
      ),
    );
  }
}

class NewsWebView extends StatelessWidget {
  final String url;

  NewsWebView(this.url);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WebView(
        initialUrl: url,
        javascriptMode: JavascriptMode.unrestricted,
      ),
    );
  }
}

class SavedNewsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(onPressed: (){
            Navigator.pop(context);
          }, icon: Icon(CupertinoIcons.back,color: Colors.white,)),
          title: Text('Saved News',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),)),
      backgroundColor: Colors.black,
      body: FutureBuilder<List<News>>(
        future: _getSavedNews(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            List<News>? savedNews = snapshot.data;
            if (savedNews == null || savedNews.isEmpty) {
              return Center(child: Text('No saved news'));
            }
            return ListView.builder(
              itemCount: savedNews.length,
              padding: EdgeInsetsDirectional.only(bottom: 50,top: 50),
              itemBuilder: (context, index) {
                return SavedNewsTile(savedNews[index]);
              },
            );
          }
        },
      ),
    );
  }

  Future<List<News>> _getSavedNews() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedNews = prefs.getStringList('saved_news');
    if (savedNews == null) return [];
    return savedNews.map((jsonString) => News.fromJson(jsonDecode(jsonString))).toList();
  }
}

class SavedNewsTile extends StatelessWidget {
  final News news;

  SavedNewsTile(this.news);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Material(
        elevation: 0,
        child: Container(
          color: Colors.grey,
            child: Column(
              children: [
                SizedBox(
                height: 10,
              ),
                Text(news.title,style: TextStyle(fontWeight: FontWeight.bold),),
              ],
            )),
      ),
      subtitle: Material(
        shadowColor: Colors.white,
        elevation: 10,
        child: Container(
            color: Colors.grey,
            child: Column(
              children: [
                SizedBox(
                  height: 20,
                ),
                Row(
                  children: [
                    Text(
                      'Uploaded by ',
                      style: TextStyle(fontWeight: FontWeight.w300, color: Colors.black),
                    ),
                    Text(
                      '${news.source}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ],
                ),
            SizedBox(height: 20),
            Row(
              children: [
                Text(
                  'Uploaded on ',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.w300),
                ),
                Text(
                  '${news.pubDate}',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
                ]
            )
              ],
            )),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NewsWebView(news.link)),
        );
      },
    );
  }
}

Future<List<News>> fetchNews() async {
  final response = await http.get(
    Uri.https(
      'yahoo-finance15.p.rapidapi.com',
      '/api/v1/markets/news',
      {'tickers': 'AAPL,TSLA'},
    ),
    headers: {
      'X-RapidAPI-Key': '6992fa44c5msh33494370d8be396p1025d7jsnf75644f6e3ff',
      'X-RapidAPI-Host': 'yahoo-finance15.p.rapidapi.com',
    },
  );

  if (response.statusCode == 200) {
    Map<String, dynamic> responseData = json.decode(response.body);
    List<dynamic> data = responseData['body']; // Accessing the 'body' key
    List<News> newsList = data.map((item) => News.fromJson(item)).toList();
    return newsList;
  } else {
    throw Exception('Failed to load news');
  }
}
