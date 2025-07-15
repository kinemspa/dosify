import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Base class for help card configuration
class HelpCardConfig {
  final String title;
  final String content;
  final IconData? icon;
  final List<String>? steps;
  final bool initiallyExpanded;
  final String? storageKey;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? titleColor;
  final String? accessibilityLabel;

  const HelpCardConfig({
    required this.title,
    required this.content,
    this.icon = Icons.help_outline,
    this.steps,
    this.initiallyExpanded = false,
    this.storageKey,
    this.backgroundColor,
    this.iconColor,
    this.titleColor,
    this.accessibilityLabel,
  });
}

/// A collapsible help card with a title and content
class CollapsibleHelpCard extends StatefulWidget {
  final String title;
  final Widget content;
  final bool initiallyExpanded;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? titleColor;
  final String? accessibilityLabel;
  final Duration animationDuration;

  const CollapsibleHelpCard({
    super.key,
    required this.title,
    required this.content,
    this.initiallyExpanded = false,
    this.icon = Icons.help_outline,
    this.backgroundColor,
    this.iconColor,
    this.titleColor,
    this.accessibilityLabel,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  /// Create from a HelpCardConfig
  factory CollapsibleHelpCard.fromConfig(HelpCardConfig config) {
    return CollapsibleHelpCard(
      title: config.title,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(config.content),
          if (config.steps != null && config.steps!.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...List.generate(
              config.steps!.length,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${index + 1}. '),
                    Expanded(
                      child: Text(config.steps![index]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      icon: config.icon,
      initiallyExpanded: config.initiallyExpanded,
      backgroundColor: config.backgroundColor,
      iconColor: config.iconColor,
      titleColor: config.titleColor,
      accessibilityLabel: config.accessibilityLabel,
    );
  }

  @override
  State<CollapsibleHelpCard> createState() => _CollapsibleHelpCardState();
}

class _CollapsibleHelpCardState extends State<CollapsibleHelpCard> with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
      value: _isExpanded ? 1.0 : 0.0,
    );
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final backgroundColor = widget.backgroundColor ?? 
        theme.cardColor;
    
    final iconColor = widget.iconColor ?? 
        colorScheme.primary;
    
    final titleColor = widget.titleColor ?? 
        theme.textTheme.titleMedium?.color ?? 
        colorScheme.onSurface;

    return Card(
      margin: EdgeInsets.zero,
      color: backgroundColor,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            label: widget.accessibilityLabel ?? 
                'Help card: ${widget.title}. Tap to ${_isExpanded ? 'collapse' : 'expand'}',
            child: InkWell(
              onTap: _toggleExpanded,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (widget.icon != null)
                      Icon(
                        widget.icon,
                        color: iconColor,
                      ),
                    if (widget.icon != null)
                      const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                    ),
                    RotationTransition(
                      turns: _rotationAnimation,
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: iconColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ClipRect(
            child: SizeTransition(
              sizeFactor: _expandAnimation,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: widget.content,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A compact help card with a title and content
class CompactHelpCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData? icon;
  final List<String>? steps;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? titleColor;
  final String? accessibilityLabel;

  const CompactHelpCard({
    super.key,
    required this.title,
    required this.content,
    this.icon = Icons.help_outline,
    this.steps,
    this.backgroundColor,
    this.iconColor,
    this.titleColor,
    this.accessibilityLabel,
  });

  /// Create from a HelpCardConfig
  factory CompactHelpCard.fromConfig(HelpCardConfig config) {
    return CompactHelpCard(
      title: config.title,
      content: config.content,
      icon: config.icon,
      steps: config.steps,
      backgroundColor: config.backgroundColor,
      iconColor: config.iconColor,
      titleColor: config.titleColor,
      accessibilityLabel: config.accessibilityLabel,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CollapsibleHelpCard(
      title: title,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(content),
          if (steps != null && steps!.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...List.generate(
              steps!.length,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${index + 1}. '),
                    Expanded(
                      child: Text(steps![index]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      icon: icon,
      backgroundColor: backgroundColor,
      iconColor: iconColor,
      titleColor: titleColor,
      accessibilityLabel: accessibilityLabel,
    );
  }
}

/// A simple help card with no collapsing
class SimpleHelpCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? titleColor;
  final String? accessibilityLabel;

  const SimpleHelpCard({
    super.key,
    required this.title,
    required this.content,
    this.icon = Icons.help_outline,
    this.backgroundColor,
    this.iconColor,
    this.titleColor,
    this.accessibilityLabel,
  });

  /// Create from a HelpCardConfig
  factory SimpleHelpCard.fromConfig(HelpCardConfig config) {
    return SimpleHelpCard(
      title: config.title,
      content: config.content,
      icon: config.icon,
      backgroundColor: config.backgroundColor,
      iconColor: config.iconColor,
      titleColor: config.titleColor,
      accessibilityLabel: config.accessibilityLabel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final backgroundColor = this.backgroundColor ?? 
        theme.cardColor;
    
    final iconColor = this.iconColor ?? 
        colorScheme.primary;
    
    final titleColor = this.titleColor ?? 
        theme.textTheme.titleMedium?.color ?? 
        colorScheme.onSurface;

    return Semantics(
      label: accessibilityLabel ?? 'Help card: $title',
      child: Card(
        margin: EdgeInsets.zero,
        color: backgroundColor,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null)
                    Icon(
                      icon,
                      color: iconColor,
                    ),
                  if (icon != null)
                    const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                content,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A collapsible help card that can be dismissed and its state saved to SharedPreferences
class PersistentHelpCard extends StatefulWidget {
  final String title;
  final String content;
  final IconData? icon;
  final List<String>? steps;
  final String storageKey;
  final bool initiallyExpanded;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? titleColor;
  final String? accessibilityLabel;
  final String dismissText;

  const PersistentHelpCard({
    super.key,
    required this.title,
    required this.content,
    this.icon = Icons.help_outline,
    this.steps,
    required this.storageKey,
    this.initiallyExpanded = true,
    this.backgroundColor,
    this.iconColor,
    this.titleColor,
    this.accessibilityLabel,
    this.dismissText = "Don't show again",
  });

  /// Create from a HelpCardConfig
  factory PersistentHelpCard.fromConfig(HelpCardConfig config) {
    assert(config.storageKey != null, 'storageKey must be provided for PersistentHelpCard');
    return PersistentHelpCard(
      title: config.title,
      content: config.content,
      icon: config.icon,
      steps: config.steps,
      storageKey: config.storageKey!,
      initiallyExpanded: config.initiallyExpanded,
      backgroundColor: config.backgroundColor,
      iconColor: config.iconColor,
      titleColor: config.titleColor,
      accessibilityLabel: config.accessibilityLabel,
    );
  }

  @override
  State<PersistentHelpCard> createState() => _PersistentHelpCardState();
}

class _PersistentHelpCardState extends State<PersistentHelpCard> with SingleTickerProviderStateMixin {
  bool _isDismissed = false;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _loadDismissState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isDismissed = true;
        });
      }
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDismissState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDismissed = prefs.getBool('help_card_${widget.storageKey}_dismissed') ?? false;
      
      if (mounted) {
        setState(() {
          _isDismissed = isDismissed;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading help card state: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveDismissState(bool dismissed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('help_card_${widget.storageKey}_dismissed', dismissed);
    } catch (e) {
      debugPrint('Error saving help card state: $e');
    }
  }
  
  void _dismiss() {
    _animationController.forward();
    _saveDismissState(true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    if (_isDismissed) {
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: _opacityAnimation,
      child: Stack(
        children: [
          CompactHelpCard(
            title: widget.title,
            content: widget.content,
            icon: widget.icon,
            steps: widget.steps,
            backgroundColor: widget.backgroundColor,
            iconColor: widget.iconColor,
            titleColor: widget.titleColor,
            accessibilityLabel: widget.accessibilityLabel,
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: Semantics(
              button: true,
              label: 'Dismiss this help card and don\'t show it again',
              child: TextButton(
                onPressed: _dismiss,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  widget.dismissText,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Extension to make help cards collapsible
extension HelpCardExtensions on Widget {
  Widget makeCollapsible({
    bool initiallyExpanded = false,
    Duration animationDuration = const Duration(milliseconds: 200),
  }) {
    if (this is CompactHelpCard) {
      final card = this as CompactHelpCard;
      return CollapsibleHelpCard(
        title: card.title,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(card.content),
            if (card.steps != null && card.steps!.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...List.generate(
                card.steps!.length,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${index + 1}. '),
                      Expanded(
                        child: Text(card.steps![index]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        icon: card.icon,
        initiallyExpanded: initiallyExpanded,
        backgroundColor: card.backgroundColor,
        iconColor: card.iconColor,
        titleColor: card.titleColor,
        accessibilityLabel: card.accessibilityLabel,
        animationDuration: animationDuration,
      );
    }
    return this;
  }
} 