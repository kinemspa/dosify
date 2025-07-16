import 'package:flutter/material.dart';
import '../services/offline_sync_service.dart';

/// A dialog for resolving sync conflicts
/// 
/// This widget presents the user with options to resolve data conflicts
/// that occur during synchronization between local and remote data.
class ConflictResolutionDialog extends StatefulWidget {
  final ConflictResolutionItem conflict;
  final Function(ConflictResolutionStrategy strategy, Map<String, dynamic>? customData) onResolve;

  const ConflictResolutionDialog({
    super.key,
    required this.conflict,
    required this.onResolve,
  });

  @override
  State<ConflictResolutionDialog> createState() => _ConflictResolutionDialogState();

  /// Show the conflict resolution dialog
  static Future<void> show({
    required BuildContext context,
    required ConflictResolutionItem conflict,
    required Function(ConflictResolutionStrategy strategy, Map<String, dynamic>? customData) onResolve,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ConflictResolutionDialog(
          conflict: conflict,
          onResolve: onResolve,
        );
      },
    );
  }
}

class _ConflictResolutionDialogState extends State<ConflictResolutionDialog> {
  ConflictResolutionStrategy _selectedStrategy = ConflictResolutionStrategy.useLocal;
  bool _showDetails = false;
  final Map<String, dynamic> _customData = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.sync_problem, color: Colors.orange),
          const SizedBox(width: 8),
          const Text('Sync Conflict'),
          const Spacer(),
          IconButton(
            icon: Icon(_showDetails ? Icons.expand_less : Icons.expand_more),
            onPressed: () => setState(() => _showDetails = !_showDetails),
            tooltip: _showDetails ? 'Hide Details' : 'Show Details',
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A conflict was detected while syncing your data. '
              'The same item was modified both locally and remotely.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            
            if (_showDetails) ...[
              _buildConflictDetails(),
              const SizedBox(height: 16),
            ],
            
            _buildResolutionOptions(),
            
            if (_selectedStrategy == ConflictResolutionStrategy.merge) ...[
              const SizedBox(height: 16),
              _buildMergeOptions(),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _handleResolve,
          child: const Text('Resolve'),
        ),
      ],
    );
  }

  Widget _buildConflictDetails() {
    return ExpansionTile(
      title: const Text('Conflict Details'),
      initiallyExpanded: _showDetails,
      children: [
        _buildDataComparison(),
      ],
    );
  }

  Widget _buildDataComparison() {
    final conflictingFields = widget.conflict.conflictData.conflictingFields;
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.phone_android, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Local Version',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Modified: ${_formatDateTime(widget.conflict.conflictData.localTimestamp)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cloud, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Remote Version',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Modified: ${_formatDateTime(widget.conflict.conflictData.remoteTimestamp)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        ...conflictingFields.map((field) => _buildFieldComparison(field)),
      ],
    );
  }

  Widget _buildFieldComparison(String field) {
    final localValue = widget.conflict.conflictData.localData[field];
    final remoteValue = widget.conflict.conflictData.remoteData[field];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    localValue?.toString() ?? 'null',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    remoteValue?.toString() ?? 'null',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResolutionOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Resolution Strategy:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        RadioListTile<ConflictResolutionStrategy>(
          title: const Row(
            children: [
              Icon(Icons.phone_android, size: 16, color: Colors.blue),
              SizedBox(width: 8),
              Text('Use Local Version'),
            ],
          ),
          subtitle: const Text('Keep your local changes'),
          value: ConflictResolutionStrategy.useLocal,
          groupValue: _selectedStrategy,
          onChanged: (value) => setState(() => _selectedStrategy = value!),
        ),
        
        RadioListTile<ConflictResolutionStrategy>(
          title: const Row(
            children: [
              Icon(Icons.cloud, size: 16, color: Colors.green),
              SizedBox(width: 8),
              Text('Use Remote Version'),
            ],
          ),
          subtitle: const Text('Use the version from the server'),
          value: ConflictResolutionStrategy.useRemote,
          groupValue: _selectedStrategy,
          onChanged: (value) => setState(() => _selectedStrategy = value!),
        ),
        
        RadioListTile<ConflictResolutionStrategy>(
          title: const Row(
            children: [
              Icon(Icons.merge_type, size: 16, color: Colors.orange),
              SizedBox(width: 8),
              Text('Merge Changes'),
            ],
          ),
          subtitle: const Text('Combine both versions'),
          value: ConflictResolutionStrategy.merge,
          groupValue: _selectedStrategy,
          onChanged: (value) => setState(() => _selectedStrategy = value!),
        ),
      ],
    );
  }

  Widget _buildMergeOptions() {
    final conflictingFields = widget.conflict.conflictData.conflictingFields;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Merge Options:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose which version to use for each conflicting field:',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        
        ...conflictingFields.map((field) => _buildFieldMergeOption(field)),
      ],
    );
  }

  Widget _buildFieldMergeOption(String field) {
    final localValue = widget.conflict.conflictData.localData[field];
    final remoteValue = widget.conflict.conflictData.remoteData[field];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: Text('Local: ${localValue?.toString() ?? 'null'}'),
                  value: 'local',
                  groupValue: _customData[field] ?? 'local',
                  onChanged: (value) => setState(() => _customData[field] = value!),
                  dense: true,
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: Text('Remote: ${remoteValue?.toString() ?? 'null'}'),
                  value: 'remote',
                  groupValue: _customData[field] ?? 'local',
                  onChanged: (value) => setState(() => _customData[field] = value!),
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleResolve() {
    Map<String, dynamic>? customData;
    
    if (_selectedStrategy == ConflictResolutionStrategy.merge) {
      customData = Map.from(_customData);
    }
    
    widget.onResolve(_selectedStrategy, customData);
    Navigator.of(context).pop();
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

/// A simplified conflict resolution widget for quick resolution
class QuickConflictResolver extends StatelessWidget {
  final ConflictResolutionItem conflict;
  final Function(ConflictResolutionStrategy strategy) onQuickResolve;

  const QuickConflictResolver({
    super.key,
    required this.conflict,
    required this.onQuickResolve,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sync_problem, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Sync Conflict',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDateTime(conflict.detectedAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Text(
              'Conflicting fields: ${conflict.conflictData.conflictingFields.join(', ')}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => onQuickResolve(ConflictResolutionStrategy.useLocal),
                  icon: const Icon(Icons.phone_android, size: 16),
                  label: const Text('Use Local'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                
                ElevatedButton.icon(
                  onPressed: () => onQuickResolve(ConflictResolutionStrategy.useRemote),
                  icon: const Icon(Icons.cloud, size: 16),
                  label: const Text('Use Remote'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                
                OutlinedButton.icon(
                  onPressed: () => _showDetailedResolver(context),
                  icon: const Icon(Icons.merge_type, size: 16),
                  label: const Text('Advanced'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailedResolver(BuildContext context) {
    ConflictResolutionDialog.show(
      context: context,
      conflict: conflict,
      onResolve: (strategy, customData) => onQuickResolve(strategy),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

/// A widget that shows a list of all unresolved conflicts
class ConflictsList extends StatelessWidget {
  final List<ConflictResolutionItem> conflicts;
  final Function(ConflictResolutionItem conflict, ConflictResolutionStrategy strategy) onResolveConflict;

  const ConflictsList({
    super.key,
    required this.conflicts,
    required this.onResolveConflict,
  });

  @override
  Widget build(BuildContext context) {
    if (conflicts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'No Conflicts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('All data is synchronized successfully.'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: conflicts.length,
      itemBuilder: (context, index) {
        final conflict = conflicts[index];
        return QuickConflictResolver(
          conflict: conflict,
          onQuickResolve: (strategy) => onResolveConflict(conflict, strategy),
        );
      },
    );
  }
}