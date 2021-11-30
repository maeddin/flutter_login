import 'package:flutter/material.dart';

enum ExpandableContainerState {
  expanded,
  shrunk,
}

class ExpandableContainer extends StatefulWidget {
  const ExpandableContainer({
    Key? key,
    required this.child,
    required this.controller,
    this.onExpandCompleted,
    this.alignment,
    this.backgroundColor,
    this.color,
    this.width,
    this.height,
    this.padding,
    this.initialState = ExpandableContainerState.shrunk,
  }) : super(key: key);

  final AnimationController controller;
  final Function? onExpandCompleted;
  final Widget child;
  final Alignment? alignment;
  final Color? backgroundColor;
  final Color? color;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final ExpandableContainerState initialState;

  @override
  _ExpandableContainerState createState() => _ExpandableContainerState();
}

class _ExpandableContainerState extends State<ExpandableContainer> {
  late Animation<double> _sizeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _backgroundSlideAnimation;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    if (widget.initialState == ExpandableContainerState.expanded) {
      _controller = widget.controller..value = 1;
    } else {
      _controller = widget.controller..value = 0;
    }

    _sizeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, .6875, curve: Curves.bounceOut),
      reverseCurve: const Interval(0.0, .6875, curve: Curves.bounceIn),
    ));
    final baseSlideAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(.6875, 1.0, curve: Curves.fastOutSlowIn),
    );
    _backgroundSlideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(baseSlideAnimation);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1, 0),
      end: const Offset(0, 0),
    ).animate(baseSlideAnimation)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onExpandCompleted!();
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _sizeAnimation,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: AnimatedBuilder(
                child: Container(
                  color: widget.backgroundColor,
                  width: widget.width,
                  height: widget.height,
                ),
                animation: _backgroundSlideAnimation,
                builder: (context, child) {
                  return ClipRect(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: child,
                      widthFactor: _backgroundSlideAnimation.value,
                    ),
                  );
                },
              ),
            ),
          ),
          SlideTransition(
            position: _slideAnimation,
            child: Container(
              alignment: widget.alignment,
              color: widget.color,
              width: widget.width,
              height: widget.height,
              padding: widget.padding,
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}
