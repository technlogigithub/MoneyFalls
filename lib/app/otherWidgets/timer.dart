import 'dart:async';
import 'package:flutter/material.dart';

class CountdownTimerScreen extends StatefulWidget {
  final Color? textColor;
  const CountdownTimerScreen({super.key, this.textColor = Colors.white});

  @override
  CountdownTimerScreenState createState() => CountdownTimerScreenState();
}

class CountdownTimerScreenState extends State<CountdownTimerScreen> {
  late Timer _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateTimeLeft();
    _startTimer();
  }

  void _calculateTimeLeft() {
    DateTime now = DateTime.now();

    DateTime next7PM = DateTime(now.year, now.month, now.day, 19, 0, 0);

    if (now.isAfter(next7PM)) {
      next7PM = next7PM.add(const Duration(days: 1));
    }

    setState(() {
      _timeLeft = next7PM.difference(now);
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft.inSeconds <= 0) {
        _calculateTimeLeft(); // Reset time to the next target (11:30 PM)
      } else {
        setState(() {
          _timeLeft = _timeLeft - const Duration(seconds: 1);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String hours = _timeLeft.inHours.toString().padLeft(2, '0');
    String minutes = (_timeLeft.inMinutes % 60).toString().padLeft(2, '0');
    String seconds = (_timeLeft.inSeconds % 60).toString().padLeft(2, '0');

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildTimeBox(hours),
            _buildSeparator(),
            _buildTimeBox(minutes),
            _buildSeparator(),
            _buildTimeBox(seconds),
          ],
        ),
        const SizedBox(height: 4),
        // Row(
        //   mainAxisAlignment: MainAxisAlignment.start,
        //   children: [
        //     Text("Hrs",
        //         style: TextStyle(color: widget.textColor, fontSize: 16)),
        //     const SizedBox(width: 40),
        //     Text("Min",
        //         style: TextStyle(color: widget.textColor, fontSize: 16)),
        //     const SizedBox(width: 35),
        //     Text("Sec",
        //         style: TextStyle(color: widget.textColor, fontSize: 16)),
        //   ],
        // ),
      ],
    );
  }

  Widget _buildTimeBox(String value) {
    return Container(
      padding: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.bold,
          color: widget.textColor,
        ),
      ),
    );
  }

  Widget _buildSeparator() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5),
      child: Text(":", style: TextStyle(fontSize: 26, color: widget.textColor)),
    );
  }
}