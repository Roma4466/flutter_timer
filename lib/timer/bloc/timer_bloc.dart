import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_timer/ticker.dart';

part 'timer_event.dart';

part 'timer_state.dart';

class TimerBloc extends Bloc<TimerEvent, TimerState> {
  final Ticker _ticker;
  static const int _duration = 60;

  StreamSubscription<int>? _tickerSubscription;

  TimerBloc({required Ticker ticker})
      : _ticker = ticker,
        super(TimerInitial(_duration)) {
    on<TimerStarted>(
      (event, emit) {
        emit(TimerRunInProgress(event.duration));
        _tickerSubscription?.cancel();
        _tickerSubscription = _ticker
            .tick(ticks: event.duration)
            .listen((duration) => add(_TimerTicked(duration: duration)));
      },
    );

    on<_TimerTicked>(
      (event, emit) {
        emit(event.duration > 0
            ? TimerRunInProgress(event.duration)
            : TimerRunComplete());
      },
    );

    on<TimerPaused>(
      (event, emit) {
        if (state is TimerRunInProgress) {
          _tickerSubscription?.pause();
          emit(TimerRunPause(state.duration));
        }
      },
    );

    on<TimerResumed>(
      (event, emit) {
        if (state is TimerRunPause) {
          _tickerSubscription?.resume();
          emit(TimerRunInProgress(state.duration));
        }
      },
    );

    on<TimerReset>(
      (event, emit) {
        _tickerSubscription?.cancel();
        emit(const TimerInitial(_duration));
      },
    );
  }

  @override
  Future<void> close() {
    _tickerSubscription?.cancel();
    return super.close();
  }
}
