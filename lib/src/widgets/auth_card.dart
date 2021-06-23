import 'dart:math';

import 'package:another_transformer_page_view/another_transformer_page_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:quiver/iterables.dart' as quiver;
import '../constants.dart';
import 'animated_button.dart';
import 'animated_text.dart';
import 'custom_page_transformer.dart';
import 'expandable_container.dart';
import 'fade_in.dart';
import 'animated_text_form_field.dart';
import '../providers/auth.dart';
import '../providers/login_messages.dart';
import '../models/login_data.dart';
import '../dart_helper.dart';
import '../matrix.dart';
import '../paddings.dart';
import '../widget_helper.dart';

class AuthCard extends StatefulWidget {
  AuthCard({
    Key? key,
    this.padding = const EdgeInsets.all(0),
    this.loadingController,
    this.emailValidator,
    this.onSubmit,
    this.onSubmitCompleted,
    this.onSuccess,
    this.onFailed,
  }) : super(key: key);

  final EdgeInsets padding;
  final AnimationController? loadingController;
  final FormFieldValidator<String>? emailValidator;
  final Function? onSubmit;
  final Function? onSubmitCompleted;
  final Function(BuildContext, String)? onSuccess;
  final Function(BuildContext, String)? onFailed;

  @override
  AuthCardState createState() => AuthCardState();
}

class AuthCardState extends State<AuthCard> with TickerProviderStateMixin {
  GlobalKey _cardKey = GlobalKey();

  var _isLoadingFirstTime = true;
  var _pageIndex = 0;
  static const cardSizeScaleEnd = .2;

  TransformerPageController? _pageController;
  late AnimationController _formLoadingController;
  late AnimationController _routeTransitionController;
  late Animation<double> _flipAnimation;
  late Animation<double> _cardSizeAnimation;
  late Animation<double> _cardSize2AnimationX;
  late Animation<double> _cardSize2AnimationY;
  late Animation<double> _cardRotationAnimation;
  late Animation<double> _cardOverlayHeightFactorAnimation;
  late Animation<double> _cardOverlaySizeAndOpacityAnimation;

  @override
  void initState() {
    super.initState();

    _pageController = TransformerPageController();

    widget.loadingController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _isLoadingFirstTime = false;
        _formLoadingController.forward();
      }
    });

    _flipAnimation = Tween<double>(begin: pi / 2, end: 0).animate(
      CurvedAnimation(
        parent: widget.loadingController!,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      ),
    );

    _formLoadingController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1150),
      reverseDuration: Duration(milliseconds: 300),
    );

    _routeTransitionController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1100),
    );

    _cardSizeAnimation = Tween<double>(begin: 1.0, end: cardSizeScaleEnd).animate(CurvedAnimation(
      parent: _routeTransitionController,
      curve: Interval(0, .27272727 /* ~300ms */, curve: Curves.easeInOutCirc),
    ));
    // replace 0 with minPositive to pass the test
    // https://github.com/flutter/flutter/issues/42527#issuecomment-575131275
    _cardOverlayHeightFactorAnimation = Tween<double>(begin: double.minPositive, end: 1.0).animate(CurvedAnimation(
      parent: _routeTransitionController,
      curve: Interval(.27272727, .5 /* ~250ms */, curve: Curves.linear),
    ));
    _cardOverlaySizeAndOpacityAnimation = Tween<double>(begin: 1.0, end: 0).animate(CurvedAnimation(
      parent: _routeTransitionController,
      curve: Interval(.5, .72727272 /* ~250ms */, curve: Curves.linear),
    ));
    _cardSize2AnimationX = Tween<double>(begin: 1, end: 1).animate(_routeTransitionController);
    _cardSize2AnimationY = Tween<double>(begin: 1, end: 1).animate(_routeTransitionController);
    _cardRotationAnimation = Tween<double>(begin: 0, end: pi / 2).animate(CurvedAnimation(
      parent: _routeTransitionController,
      curve: Interval(.72727272, 1 /* ~300ms */, curve: Curves.easeInOutCubic),
    ));
  }

  @override
  void dispose() {
    super.dispose();

    _formLoadingController.dispose();
    _pageController!.dispose();
    _routeTransitionController.dispose();
  }

  void _switchRecovery(bool recovery) {
    final auth = Provider.of<Auth>(context, listen: false);

    auth.isRecover = recovery;
    if (recovery) {
      _pageController!.nextPage(
        duration: Duration(milliseconds: 500),
        curve: Curves.ease,
      );
      _pageIndex = 1;
    } else {
      _pageController!.previousPage(
        duration: Duration(milliseconds: 500),
        curve: Curves.ease,
      );
      _pageIndex = 0;
    }
  }

  Future<void> runLoadingAnimation() {
    if (widget.loadingController!.isDismissed) {
      return widget.loadingController!.forward().then((_) {
        if (!_isLoadingFirstTime) {
          _formLoadingController.forward();
        }
      });
    } else if (widget.loadingController!.isCompleted) {
      return _formLoadingController.reverse().then((_) => widget.loadingController!.reverse());
    }
    return Future.value(null);
  }

  Future<void> _forwardChangeRouteAnimation() {
    final isLogin = Provider.of<Auth>(context, listen: false).isLogin;
    final deviceSize = MediaQuery.of(context).size;
    final cardSize = getWidgetSize(_cardKey)!;
    // add .25 to make sure the scaling will cover the whole screen
    final widthRatio = deviceSize.width / cardSize.height + (isLogin ? .25 : .65);
    final heightRatio = deviceSize.height / cardSize.width + .25;

    _cardSize2AnimationX = Tween<double>(begin: 1.0, end: heightRatio / cardSizeScaleEnd).animate(CurvedAnimation(
      parent: _routeTransitionController,
      curve: Interval(.72727272, 1, curve: Curves.easeInOutCubic),
    ));
    _cardSize2AnimationY = Tween<double>(begin: 1.0, end: widthRatio / cardSizeScaleEnd).animate(CurvedAnimation(
      parent: _routeTransitionController,
      curve: Interval(.72727272, 1, curve: Curves.easeInOutCubic),
    ));

    widget.onSubmit!();

    return _formLoadingController.reverse().then((_) => _routeTransitionController.forward());
  }

  void _reverseChangeRouteAnimation() {
    _routeTransitionController.reverse().then((_) => _formLoadingController.forward());
  }

  void runChangeRouteAnimation() {
    if (_routeTransitionController.isCompleted) {
      _reverseChangeRouteAnimation();
    } else if (_routeTransitionController.isDismissed) {
      _forwardChangeRouteAnimation();
    }
  }

  void runChangePageAnimation() {
    final auth = Provider.of<Auth>(context, listen: false);
    _switchRecovery(!auth.isRecover);
  }

  Widget _buildLoadingAnimator({Widget? child, required ThemeData theme}) {
    Widget card;
    Widget overlay;

    // loading at startup
    card = AnimatedBuilder(
      animation: _flipAnimation,
      builder: (context, child) => Transform(
        transform: Matrix.perspective()..rotateX(_flipAnimation.value),
        alignment: Alignment.center,
        child: child,
      ),
      child: child,
    );

    // change-route transition
    overlay = Padding(
      padding: theme.cardTheme.margin!,
      child: AnimatedBuilder(
        animation: _cardOverlayHeightFactorAnimation,
        builder: (context, child) => ClipPath.shape(
          shape: theme.cardTheme.shape!,
          child: FractionallySizedBox(
            heightFactor: _cardOverlayHeightFactorAnimation.value,
            alignment: Alignment.topCenter,
            child: child,
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(color: theme.accentColor),
        ),
      ),
    );

    overlay = ScaleTransition(
      scale: _cardOverlaySizeAndOpacityAnimation,
      child: FadeTransition(
        opacity: _cardOverlaySizeAndOpacityAnimation,
        child: overlay,
      ),
    );

    return Stack(
      children: <Widget>[
        card,
        Positioned.fill(child: overlay),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deviceSize = MediaQuery.of(context).size;
    Widget current = Container(
      height: deviceSize.height,
      width: deviceSize.width,
      padding: widget.padding,
      child: TransformerPageView(
        physics: NeverScrollableScrollPhysics(),
        pageController: _pageController,
        itemCount: 2,

        /// Need to keep track of page index because soft keyboard will
        /// make page view rebuilt
        index: _pageIndex,
        transformer: CustomPageTransformer(),
        itemBuilder: (BuildContext context, int index) {
          final child = (index == 0)
              ? _buildLoadingAnimator(
                  theme: theme,
                  child: _LoginCard(
                    key: _cardKey,
                    onFailed: widget.onFailed,
                    loadingController: _isLoadingFirstTime ? _formLoadingController : (_formLoadingController..value = 1.0),
                    onSwitchRecoveryPassword: () => _switchRecovery(true),
                    onSubmitCompleted: () {
                      _forwardChangeRouteAnimation().then((_) {
                        widget.onSubmitCompleted!();
                      });
                    },
                  ),
                )
              : _RecoverCard(
                  onSuccess: widget.onSuccess,
                  onFailed: widget.onFailed,
                  emailValidator: widget.emailValidator,
                  onSwitchLogin: () => _switchRecovery(false),
                );

          return Align(
            alignment: Alignment.topCenter,
            child: child,
          );
        },
      ),
    );

    return AnimatedBuilder(
      animation: _cardSize2AnimationX,
      builder: (context, snapshot) {
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..rotateZ(_cardRotationAnimation.value)
            ..scale(_cardSizeAnimation.value, _cardSizeAnimation.value)
            ..scale(_cardSize2AnimationX.value, _cardSize2AnimationY.value),
          child: current,
        );
      },
    );
  }
}

class _LoginCard extends StatefulWidget {
  _LoginCard({
    Key? key,
    this.loadingController,
    required this.onSwitchRecoveryPassword,
    this.onSwitchAuth,
    this.onSubmitCompleted,
    this.onFailed,
  }) : super(key: key);

  final AnimationController? loadingController;
  final Function onSwitchRecoveryPassword;
  final Function? onSwitchAuth;
  final Function? onSubmitCompleted;
  final Function(BuildContext, String)? onFailed;

  @override
  _LoginCardState createState() => _LoginCardState();
}

class _LoginCardState extends State<_LoginCard> with TickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey();

  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  var _isLoading = false;
  var _isSubmitting = false;
  var _showShadow = true;

  /// switch between login and signup
  late final AnimationController _loadingController;
  late final AnimationController _switchAuthController;
  late AnimationController _postSwitchAuthController;
  AnimationController? _submitController;

  Interval? _nameTextFieldLoadingAnimationInterval;
  Interval? _passTextFieldLoadingAnimationInterval;
  Interval? _textButtonLoadingAnimationInterval;
  late Animation<double> _buttonScaleAnimation;

  bool get buttonEnabled => !_isLoading && !_isSubmitting;

  @override
  void initState() {
    super.initState();

    final messages = Provider.of<LoginMessages>(context, listen: false);
    final auth = Provider.of<Auth>(context, listen: false);
    auth.values = messages.fieldData.map((e) => InputData('')).toList();
    _loadingController = widget.loadingController ??
        (AnimationController(
          vsync: this,
          duration: Duration(milliseconds: 1150),
          reverseDuration: Duration(milliseconds: 300),
        )..value = 1.0);

    _loadingController.addStatusListener(handleLoadingAnimationStatus);

    _switchAuthController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _postSwitchAuthController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 150),
    );
    _submitController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );

    _nameTextFieldLoadingAnimationInterval = const Interval(0, .85);
    _passTextFieldLoadingAnimationInterval = const Interval(.15, 1.0);
    _textButtonLoadingAnimationInterval = const Interval(.6, 1.0, curve: Curves.easeOut);
    _buttonScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _loadingController,
      curve: Interval(.4, 1.0, curve: Curves.easeOutBack),
    ));
  }

  void handleLoadingAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.forward) {
      setState(() => _isLoading = true);
    }
    if (status == AnimationStatus.completed) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _loadingController.removeStatusListener(handleLoadingAnimationStatus);
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();

    _switchAuthController.dispose();
    _postSwitchAuthController.dispose();
    _submitController!.dispose();

    super.dispose();
  }

  void _switchAuthMode() {
    final auth = Provider.of<Auth>(context, listen: false);
    final newAuthMode = auth.switchAuth();

    if (newAuthMode == AuthMode.Signup) {
      _switchAuthController.forward();
    } else {
      _switchAuthController.reverse();
    }
  }

  Future<bool> _submit() async {
    // a hack to force unfocus the soft keyboard. If not, after change-route
    // animation completes, it will trigger rebuilding this widget and show all
    // textfields and buttons again before going to new route
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return false;
    }

    _formKey.currentState!.save();
    _submitController!.forward();
    setState(() => _isSubmitting = true);
    final auth = Provider.of<Auth>(context, listen: false);
    String? error;

    if (auth.isLogin) {
      error = await auth.onLogin!(LoginData(auth.values!.map((e) => e.value).toList()));
    } else {
      error = await auth.onSignup!(LoginData(auth.values!.map((e) => e.value).toList()));
    }

    if(!mounted) return true;

    // workaround to run after _cardSizeAnimation in parent finished
    // need a cleaner way but currently it works so..
    Future.delayed(const Duration(milliseconds: 450), () {
      setState(() => _showShadow = false);
    });

    _submitController!.reverse();

    if (!DartHelper.isNullOrEmpty(error)) {
      (widget.onFailed ?? showErrorToast).call(context, error!);
      Future.delayed(const Duration(milliseconds: 271), () {
        setState(() => _showShadow = true);
      });
      setState(() => _isSubmitting = false);
      return false;
    }

    widget.onSubmitCompleted!();

    return true;
  }

  Widget _buildNameField(double width, LoginMessages messages, Auth auth) {
    return AnimatedTextFormField(
      width: width,
      loadingController: _loadingController,
      interval: _nameTextFieldLoadingAnimationInterval,
      //labelText: messages.usernameHint,
      prefixIcon: Icon(FontAwesomeIcons.solidUserCircle),
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (value) {
        FocusScope.of(context).requestFocus(_passwordFocusNode);
      },
      onSaved: (value) => auth.email = value??'',
    );
  }

  Widget _buildFieldData(double width, FieldData data, Auth auth, InputData? inputData, {bool submitOnDone = false, FocusNode? focusNode, FocusNode? nextFocusNode}) {
    return AnimatedPasswordTextFormField(
      animatedWidth: width,
      loadingController: _loadingController,
      interval: _passTextFieldLoadingAnimationInterval,
      labelText: data.label,
      textInputAction: submitOnDone ? TextInputAction.done : TextInputAction.next,
      autofillHints: data.autofillHints,
      //focusNode: _passwordFocusNode,
      /*onFieldSubmitted: (value) {if (auth.isLogin) {
          _submit();
        } else {
          // SignUp
          FocusScope.of(context).requestFocus(_confirmPasswordFocusNode);
        }},*/
      hide: data.hide,
      prefixIcon: data.icon,
      validator: (s) => data.validator?.call(s??'', auth.values!.map((e) => e.value).toList()),
      onChanged: (value) => inputData!.value = value,
      onFieldSubmitted: submitOnDone ? (s) => _submit() : (s) => nextFocusNode!.requestFocus(),
      focusNode: focusNode,
    );
  }

  /*Widget _buildPasswordField(double width, LoginMessages messages, Auth auth) {
    return AnimatedPasswordTextFormField(
      animatedWidth: width,
      loadingController: _loadingController,
      interval: _passTextFieldLoadingAnimationInterval,
      //labelText: messages.passwordHint,
      textInputAction: auth.isLogin ? TextInputAction.done : TextInputAction.next,
      focusNode: _passwordFocusNode,
      */ /*onFieldSubmitted: (value) {if (auth.isLogin) {
          _submit();
        } else {
          // SignUp
          FocusScope.of(context).requestFocus(_confirmPasswordFocusNode);
        }},*/ /*
      validator: widget.passwordValidator,
      onSaved: (value) => auth.password = value,
    );
  }*/

  /*Widget _buildConfirmPasswordField(double width, LoginMessages messages, Auth auth) {
    return AnimatedPasswordTextFormField(
      animatedWidth: width,
      enabled: auth.isSignup,
      loadingController: _loadingController,
      inertiaController: _postSwitchAuthController,
      inertiaDirection: TextFieldInertiaDirection.right,
      //labelText: messages.confirmPasswordHint,
      controller: _confirmPassController,
      textInputAction: TextInputAction.done,
      focusNode: _confirmPasswordFocusNode,
      onFieldSubmitted: (value) => _submit(),
      validator: auth.isSignup
          ? (value) {
              if (value != _passController.text) {
                return messages.confirmPasswordError;
              }
              return null;
            }
          : (value) => null,
      onSaved: (value) => auth.confirmPassword = value,
    );
  }*/

  Widget _buildForgotPassword(ThemeData theme, LoginMessages messages) {
    return FadeIn(
      controller: _loadingController,
      fadeDirection: FadeDirection.bottomToTop,
      offset: .5,
      curve: _textButtonLoadingAnimationInterval,
      child: TextButton(
        child: Text(
          messages.forgotPasswordButton,
          style: theme.textTheme.body1,
          textAlign: TextAlign.left,
        ),
        onPressed: buttonEnabled
            ? () {
                // save state to populate email field on recovery card
                _formKey.currentState!.save();
                widget.onSwitchRecoveryPassword();
              }
            : null,
      ),
    );
  }

  Widget _buildSubmitButton(ThemeData theme, LoginMessages messages, Auth auth) {
    return ScaleTransition(
      scale: _buttonScaleAnimation,
      child: AnimatedButton(
        controller: _submitController,
        text: auth.isLogin ? messages.loginButton : messages.signupButton,
        onPressed: _submit,
      ),
    );
  }

  Widget _buildSwitchAuthButton(ThemeData theme, LoginMessages messages, Auth auth) {
    return FadeIn(
      controller: _loadingController,
      offset: .5,
      curve: _textButtonLoadingAnimationInterval,
      fadeDirection: FadeDirection.topToBottom,
      child: FlatButton(
        child: AnimatedText(
          text: auth.isSignup ? messages.loginButton : messages.signupButton,
          textRotation: AnimatedTextRotation.down,
        ),
        disabledTextColor: theme.primaryColor,
        onPressed: buttonEnabled ? _switchAuthMode : null,
        padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 4),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textColor: theme.primaryColor,
      ),
    );
  }

  Widget getFieldDataContainer(
    bool isLogin,
    double cardPadding,
    double cardWidth,
    double textFieldWidth,
    FieldData fieldData,
    InputData? inputData,
    Auth auth, {
    bool isLast = false,
    EdgeInsetsGeometry padding = const EdgeInsets.only(
      left: 10,
      right: 10,
      top: 10,
    ),
    FocusNode? focusNode,
    FocusNode? nextFocusNode,
  }) {
    ThemeData theme = Theme.of(context);
    return fieldData.mode == Mode.LOGIN
        ? Container(
            padding: padding,
            width: cardWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildFieldData(textFieldWidth, fieldData, auth, inputData, submitOnDone: isLast, focusNode: focusNode, nextFocusNode: nextFocusNode),
              ],
            ),
          )
        : ExpandableContainer(
            backgroundColor: theme.accentColor,
            controller: _switchAuthController,
            initialState: isLogin ? ExpandableContainerState.shrunk : ExpandableContainerState.expanded,
            alignment: Alignment.topLeft,
            color: theme.cardTheme.color,
            width: cardWidth,
            padding: EdgeInsets.symmetric(
              horizontal: cardPadding,
              vertical: cardPadding / 2,
            ),
            onExpandCompleted: () => _postSwitchAuthController.forward(),
            child: _buildFieldData(textFieldWidth, fieldData, auth, inputData, submitOnDone: isLast, focusNode: focusNode, nextFocusNode: nextFocusNode),
          );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context, listen: true);
    final isLogin = auth.isLogin;
    final messages = Provider.of<LoginMessages>(context, listen: false);
    final theme = Theme.of(context);
    final deviceSize = MediaQuery.of(context).size;
    final cardWidth = min(deviceSize.width * 0.75, 360.0);
    const cardPadding = 16.0;
    final textFieldWidth = cardWidth - cardPadding * 2;
    final int lastLoginField = messages.fieldData.lastIndexWhere((element) => element.mode == Mode.LOGIN);
    final int length = messages.fieldData.length;
    final List<FocusNode> focusNodes = messages.fieldData.map((data) => FocusNode(skipTraversal: data.mode != Mode.LOGIN && auth.isLogin)).toList();
    final List iterable = quiver.zip([
      messages.fieldData,
      auth.values!,
      focusNodes,
      List.generate(length, (index) => index),
    ]).toList();
    final authForm = Form(
      key: _formKey,
      child: Column(
        children: <Widget>[Container(height: cardPadding + 10),
              AutofillGroup(
                child: Column(children: iterable.map((e) {
                  int index = e[3];
                  bool isLast = isLogin ? (index >= lastLoginField) : (index == length - 1);
                  return getFieldDataContainer(
                    isLogin,
                    cardPadding,
                    cardWidth,
                    textFieldWidth,
                    e[0],
                    e[1],
                    auth,
                    isLast: isLast,
                    padding: EdgeInsets.symmetric(
                      horizontal: cardPadding,
                      vertical: cardPadding / 2,
                    ),
                    focusNode: e[2],
                    nextFocusNode: isLast
                        ? null
                        : (auth.isLogin
                        ? iterable.skip(index + 1).cast<List<Object?>?>().firstWhere((element) => (element![0] as FieldData).mode == Mode.LOGIN, orElse: () => [null, null, null])?.elementAt(2) as FocusNode?
                        : focusNodes[index + 1]),
                  );
                }).toList(),),
              ),
              Container(
                padding: Paddings.fromRBL(cardPadding),
                width: cardWidth,
                child: Column(
                  children: <Widget>[
                    _buildForgotPassword(theme, messages),
                    _buildSubmitButton(theme, messages, auth),
                    _buildSwitchAuthButton(theme, messages, auth),
                  ],
                ),
              ),
            ],
      ),
    );

    return FittedBox(
      child: Card(
        elevation: _showShadow ? theme.cardTheme.elevation : 0,
        child: authForm,
      ),
    );
  }
}

class _RecoverCard extends StatefulWidget {
  _RecoverCard({Key? key, required this.emailValidator, required this.onSwitchLogin, this.onSuccess, this.onFailed}) : super(key: key);

  final FormFieldValidator<String>? emailValidator;
  final Function onSwitchLogin;
  final Function(BuildContext, String)? onSuccess;
  final Function(BuildContext, String)? onFailed;

  @override
  _RecoverCardState createState() => _RecoverCardState();
}

class _RecoverCardState extends State<_RecoverCard> with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formRecoverKey = GlobalKey();

  TextEditingController? _nameController;

  var _isSubmitting = false;

  AnimationController? _submitController;

  @override
  void initState() {
    super.initState();

    final auth = Provider.of<Auth>(context, listen: false);
    _nameController = new TextEditingController(text: auth.email);

    _submitController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _submitController!.dispose();
  }

  Future<bool> _submit() async {
    if (!_formRecoverKey.currentState!.validate()) {
      return false;
    }
    final auth = Provider.of<Auth>(context, listen: false);
    final messages = Provider.of<LoginMessages>(context, listen: false);

    _formRecoverKey.currentState!.save();
    _submitController!.forward();
    setState(() => _isSubmitting = true);
    final error = await auth.onRecoverPassword!(auth.email)!;

    if (error != null) {
      (widget.onFailed ?? showErrorToast).call(context, error);
      setState(() => _isSubmitting = false);
      _submitController!.reverse();
      return false;
    } else {
      (widget.onSuccess ?? showSuccessToast).call(context, messages.recoverPasswordSuccess);
      setState(() => _isSubmitting = false);
      _submitController!.reverse();
      return true;
    }
  }

  Widget _buildRecoverNameField(double width, LoginMessages messages, Auth auth) {
    FieldData data = messages.recoveryData;
    return AnimatedTextFormField(
      controller: _nameController,
      width: width,
      labelText: data.label,
      prefixIcon: data.icon,
      keyboardType: data.inputType,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (value) => _submit(),
      validator: (s) => data.validator?.call(s??'', [s??'']),
      onSaved: (value) => auth.email = value??'',
    );
  }

  Widget _buildRecoverButton(ThemeData theme, LoginMessages messages) {
    return AnimatedButton(
      controller: _submitController,
      text: messages.recoverPasswordButton,
      onPressed: !_isSubmitting ? _submit : null,
    );
  }

  Widget _buildBackButton(ThemeData theme, LoginMessages messages) {
    return FlatButton(
      child: Text(messages.goBackButton),
      onPressed: !_isSubmitting
          ? () {
              _formRecoverKey.currentState!.save();
              widget.onSwitchLogin();
            }
          : null,
      padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textColor: theme.primaryColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Provider.of<Auth>(context, listen: false);
    final messages = Provider.of<LoginMessages>(context, listen: false);
    final deviceSize = MediaQuery.of(context).size;
    final cardWidth = min(deviceSize.width * 0.75, 360.0);
    const cardPadding = 16.0;
    final textFieldWidth = cardWidth - cardPadding * 2;

    return WillPopScope(
      onWillPop: () async {
        if (!_isSubmitting) {
          _formRecoverKey.currentState!.save();
          widget.onSwitchLogin();
        }
        return false;
      },
      child: FittedBox(
        // width: cardWidth,
        child: Card(
          child: Container(
            padding: const EdgeInsets.only(
              left: cardPadding,
              top: cardPadding + 10.0,
              right: cardPadding,
              bottom: cardPadding,
            ),
            width: cardWidth,
            alignment: Alignment.center,
            child: Form(
              key: _formRecoverKey,
              child: Column(
                children: [
                  Text(
                    messages.recoverPasswordIntro,
                    key: kRecoverPasswordIntroKey,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.body1,
                  ),
                  SizedBox(height: 20),
                  _buildRecoverNameField(textFieldWidth, messages, auth),
                  SizedBox(height: 20),
                  Text(
                    messages.recoverPasswordDescription,
                    key: kRecoverPasswordDescriptionKey,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.body1,
                  ),
                  SizedBox(height: 26),
                  _buildRecoverButton(theme, messages),
                  _buildBackButton(theme, messages),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
