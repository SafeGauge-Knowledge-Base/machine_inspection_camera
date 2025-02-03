part of 'camera_bloc.dart';

abstract class CameraEvent extends Equatable {
  const CameraEvent();

  @override
  List<Object> get props => [];
}

class StartLive extends CameraEvent {
  const StartLive();

  @override
  List<Object> get props => [];
}

class onPushImage extends CameraEvent {
  final Uint8List image;

  const onPushImage(this.image);

  @override
  List<Object> get props => [image];
}
