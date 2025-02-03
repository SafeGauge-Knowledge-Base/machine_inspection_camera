part of 'camera_bloc.dart';

class CameraState extends Equatable {
  final Uint8List? image;
  final bool isStreaming;
  const CameraState({
    this.image,
    this.isStreaming = false,
  });

  @override
  List<Object?> get props => [
        image,
        isStreaming,
      ];

  CameraState copyWith({
    Uint8List? image,
    bool? isStreaming,
  }) {
    return CameraState(
      isStreaming: isStreaming ?? this.isStreaming,
      image: image ?? this.image,
    );
  }
}
