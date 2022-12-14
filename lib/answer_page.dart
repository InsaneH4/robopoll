import 'main.dart';
import 'homepage.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

var isStarted = false;

class AnswerPage extends StatefulWidget {
  final String title = "Joined Poll";

  const AnswerPage({super.key});

  @override
  State<AnswerPage> createState() => _AnswerPageState();
}

class _AnswerPageState extends State<AnswerPage> {
  var waiting = 'Waiting for host to start the poll';

  @override
  Widget build(BuildContext context) {
    double boxHeight = isMobile ? 125 : 200;
    double boxWidth = isMobile ? 175 : 350;
    var options = List<String>.filled(4, "loading...");
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              leavePollUsr(context);
            },
          ),
        ),
        body: ValueListenableBuilder<bool>(
          valueListenable: pollOver,
          builder: (context, pollOverVal, child) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  ValueListenableBuilder(
                    valueListenable: serverStream,
                    builder: (context, value, _) {
                      if (isStarted && !pollOverVal) {
                        var question = "Waiting for next question...";
                        if (value.contains("newQuestion")) {
                          question = RegExp(r':"(.*?)"')
                              .firstMatch(value)
                              ?.group(1) as String;
                          options = (RegExp(r'\[(.*?)\]')
                                  .firstMatch(value)
                                  ?.group(1) as String)
                              .replaceAll('"', '')
                              .split(',');
                        } else {
                          options = List<String>.filled(4, "...");
                        }
                        return Container(
                          margin: const EdgeInsets.only(top: 50),
                          child: Column(
                            children: <Widget>[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: <Widget>[
                                  SizedBox(
                                    width: boxWidth,
                                    height: boxHeight,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        alignment: Alignment.center,
                                        foregroundColor: Colors.white,
                                        backgroundColor: Colors.red,
                                        textStyle: const TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      onPressed: () => _answerSubmit("0"),
                                      child: Text(options[0]),
                                    ),
                                  ),
                                  SizedBox(
                                    width: boxWidth,
                                    height: boxHeight,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        alignment: Alignment.center,
                                        foregroundColor: Colors.white,
                                        backgroundColor: Colors.blue,
                                        textStyle: const TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      onPressed: () => _answerSubmit("1"),
                                      child: Text(options[1]),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                margin: const EdgeInsets.only(top: 25),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: <Widget>[
                                    SizedBox(
                                      width: boxWidth,
                                      height: boxHeight,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          alignment: Alignment.center,
                                          foregroundColor: Colors.white,
                                          backgroundColor: Colors.amber,
                                          textStyle: const TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        onPressed: () => _answerSubmit("2"),
                                        child: Text(options[2]),
                                      ),
                                    ),
                                    SizedBox(
                                      width: boxWidth,
                                      height: boxHeight,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          alignment: Alignment.center,
                                          foregroundColor: Colors.white,
                                          backgroundColor: Colors.green,
                                          textStyle: const TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        onPressed: () => _answerSubmit("3"),
                                        child: Text(options[3]),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.25,
                                width: MediaQuery.of(context).size.width * 0.9,
                                child: Container(
                                  margin: isMobile
                                      ? const EdgeInsets.only(top: 40)
                                      : const EdgeInsets.only(top: 75),
                                  child: SingleChildScrollView(
                                    child: Text(
                                        style: isMobile
                                            ? const TextStyle(
                                                fontSize: 30,
                                                color: Colors.white)
                                            : Theme.of(context)
                                                .textTheme
                                                .displayMedium,
                                        textAlign: TextAlign.center,
                                        question),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      } else if (!isStarted && !pollOverVal) {
                        return Text(
                          waiting,
                          style: isMobile
                              ? const TextStyle(fontSize: 42, color: white)
                              : Theme.of(context).textTheme.displayMedium,
                          textAlign: TextAlign.center,
                        );
                      } else if (pollOverVal) {
                        return Column(
                          children: <Widget>[
                            Text(
                              "Poll has ended",
                              style: Theme.of(context).textTheme.displayMedium,
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 50),
                              child: ElevatedButton(
                                onPressed: () {
                                  leavePollUsr(context);
                                },
                                child: const Text("Exit"),
                              ),
                            ),
                          ],
                        );
                      } else {
                        return Text(
                          'Something went wrong',
                          style: Theme.of(context).textTheme.displayMedium,
                          textAlign: TextAlign.center,
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void reconnectWs() {
    setState(() {
      channel = WebSocketChannel.connect(endpoint);
      channel.stream.listen((message) => listenMethod(message));
    });
  }

  void leavePollUsr(context) {
    channel.sink.add('leaveGame?code=$roomCode');
    flushWsStream();
    user = false;
    host = false;
    isStarted = false;
    pollOver.value = false;
    roomCode = "";
    waiting = "";
    reconnectWs();
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => const Homepage()));
  }
}

void _answerSubmit(String choice) {
  channel.sink.add("userSubmitAnswer?code=$roomCode&answer=$choice");
}

void userStart() {
  if (user && !host) {
    isStarted = true;
  }
  flushWsStream();
}
