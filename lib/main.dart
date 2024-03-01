import 'dart:convert';
import 'package:circular_progress_stack/circular_progress_stack.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

void main() {
  runApp(MyApp());
}

class News {
  final String guid;
  final String link;
  final String pubDate;
  final String source;
  final String title;

  News({
    required this.guid,
    required this.link,
    required this.pubDate,
    required this.source,
    required this.title,
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
}

class MyApp extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Set debugShowCheckedModeBanner to false
      title: 'News App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          centerTitle: true,
          title: Text(
            'NewsFlash!',
            style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
          ),
        ),
        body: LiquidPullToRefresh(
          onRefresh: fetchNews,
          child: FutureBuilder<List<News>>(
            future: fetchNews(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: AnimatedStackCircularProgressBar(
                    size: 50,
                    progressStrokeWidth: 15,
                    backStrokeWidth: 15,
                    startAngle: 0,
                    backColor: const Color(0xffD7DEE7),
                    bars: [
                      AnimatedBarValue(
                        barColor: Colors.green,
                        barValues: 1000,
                        fullProgressColors: Colors.red,
                      ),
                    ],
                  ),
                );
              } else if (snapshot.hasError) {
                print('Error: ${snapshot.error}');
                return Center(child: Text('Failed to load news',style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold
                ),)); // Display error message
              } else {
                if (snapshot.data == null || snapshot.data!.isEmpty) {
                  return Center(child: Text('No news available'));
                }
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    News news = snapshot.data![index];
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
                  },
                );
              }
            },
          ),
        ),
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
