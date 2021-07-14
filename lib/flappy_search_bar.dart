library flappy_search_bar;

import 'dart:async';

import 'package:async/async.dart';
import 'package:flappy_search_bar/scaled_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import 'search_bar_style.dart';

mixin _ControllerListener<T> on State<SearchBar<T>> {
  void onListChanged(List<T> items) {}

  void onLoading() {}

  void onClear() {}

  void onError(Error error) {}
}

class SearchBarController<T> {
  final List<T> _list = [];
  final List<T> _filteredList = [];
  final List<T> _sortedList = [];
  String _lastSearchedText;
  Future<List<T>> Function(String text) _lastSearchFunction;
  _ControllerListener _controllerListener;
  int Function(T a, T b) _lastSorting;
  CancelableOperation _cancelableOperation;

  void setListener(_ControllerListener _controllerListener) {
    this._controllerListener = _controllerListener;
  }

  void clear() {
    _controllerListener?.onClear();
  }

  void _search(
      String text, Future<List<T>> Function(String text) onSearch) async {
    _controllerListener?.onLoading();
    try {
      if (_cancelableOperation != null &&
          (!_cancelableOperation.isCompleted ||
              !_cancelableOperation.isCanceled)) {
        _cancelableOperation.cancel();
      }
      _cancelableOperation = CancelableOperation.fromFuture(
        onSearch(text),
        onCancel: () => {},
      );

      final List<T> items = await _cancelableOperation.value;
      _lastSearchFunction = onSearch;
      _lastSearchedText = text;
      _list.clear();
      _filteredList.clear();
      _sortedList.clear();
      _lastSorting = null;
      _list.addAll(items);
      _controllerListener?.onListChanged(_list);
    } catch (error) {
      _controllerListener?.onError(error);
    }
  }

  void replayLastSearch() {
    if (_lastSearchFunction != null && _lastSearchedText != null) {
      _search(_lastSearchedText, _lastSearchFunction);
    }
  }

  void removeFilter() {
    _filteredList.clear();
    if (_lastSorting == null) {
      _controllerListener?.onListChanged(_list);
    } else {
      _sortedList.clear();
      _sortedList.addAll(List<T>.from(_list));
      _sortedList.sort(_lastSorting);
      _controllerListener?.onListChanged(_sortedList);
    }
  }

  void removeSort() {
    _sortedList.clear();
    _lastSorting = null;
    _controllerListener
        ?.onListChanged(_filteredList.isEmpty ? _list : _filteredList);
  }

  void sortList(int Function(T a, T b) sorting) {
    _lastSorting = sorting;
    _sortedList.clear();
    _sortedList
        .addAll(List<T>.from(_filteredList.isEmpty ? _list : _filteredList));
    _sortedList.sort(sorting);
    _controllerListener?.onListChanged(_sortedList);
  }

  void filterList(bool Function(T item) filter) {
    _filteredList.clear();
    _filteredList.addAll(_sortedList.isEmpty
        ? _list.where(filter).toList()
        : _sortedList.where(filter).toList());
    _controllerListener?.onListChanged(_filteredList);
  }
}

/// Signature for a function that creates [ScaledTile] for a given index.
typedef ScaledTile IndexedScaledTileBuilder(int index);

class SearchBar<T> extends StatefulWidget {
  /// Future returning searched items
  final Future<List<T>> Function(String text) onSearch;

  /// List of items showed by default
  final List<T> suggestions;

  /// Callback returning the widget corresponding to a Suggestion item
  final Widget Function(T item, int index) buildSuggestion;

  /// Minimum number of chars required for a search
  final int minimumChars;

  /// Callback returning the widget corresponding to an item found
  final Widget Function(T item, int index) onItemFound;

  /// Callback returning the widget corresponding to an Error while searching
  final Widget Function(Error error) onError;

  /// Cooldown between each call to avoid too many
  final Duration debounceDuration;

  /// Widget to show when loading
  final Widget loader;

  /// Widget to show when no item were found
  final Widget emptyWidget;

  /// Widget to show by default
  final Widget placeHolder;

  /// Widget showed on left of the search bar
  final Widget icon;

  /// Widget placed between the search bar and the results
  final Widget header;

  /// Hint text of the search bar
  final String hintText;

  /// TextStyle of the hint text
  final TextStyle hintStyle;

  /// Color of the icon when search bar is active
  final Color iconActiveColor;

  /// Text style of the text in the search bar
  final TextStyle textStyle;

  /// Widget shown for cancellation
  final Widget cancellationWidget;

  /// Callback when cancel button is triggered
  final VoidCallback onCancelled;

  /// Controller used to be able to sort, filter or replay the search
  final SearchBarController searchBarController;

  /// Enable to edit the style of the search bar
  final SearchBarStyle searchBarStyle;

  /// Number of items displayed on cross axis
  final int crossAxisCount;

  /// Weather the list should take the minimum place or not
  final bool shrinkWrap;

  /// Called to get the tile at the specified index for the
  /// [SliverGridStaggeredTileLayout].
  final IndexedScaledTileBuilder indexedScaledTileBuilder;

  /// Set the scrollDirection
  final Axis scrollDirection;

  /// Spacing between tiles on main axis
  final double mainAxisSpacing;

  /// Spacing between tiles on cross axis
  final double crossAxisSpacing;

  /// Set a padding on the search bar
  final EdgeInsetsGeometry searchBarPadding;

  /// Set a padding on the header
  final EdgeInsetsGeometry headerPadding;

  /// Set a padding on the list
  final EdgeInsetsGeometry listPadding;

  /// Set a trailing icon for the header
  final Widget trailingIcon;

  /// Ratio between text-field and trailing icon widths
  final double widthRatio;

  /// Controller for the search-box's text field
  final TextEditingController searchQueryController;

  /// A function triggered upon tapping the help button
  final VoidCallback onHelp;

  SearchBar({
    Key key,
    @required this.onSearch,
    @required this.onItemFound,
    this.searchBarController,
    this.minimumChars = 3,
    this.debounceDuration = const Duration(milliseconds: 500),
    this.loader = const Center(child: CircularProgressIndicator()),
    this.onError,
    this.emptyWidget = const SizedBox.shrink(),
    this.header,
    this.placeHolder,
    this.icon = const Icon(Icons.search, color: Colors.black38,),
    this.hintText = "",
    this.hintStyle = const TextStyle(color: Color.fromRGBO(142, 142, 147, 1)),
    this.iconActiveColor = Colors.black,
    this.textStyle = const TextStyle(color: Colors.black),
    this.cancellationWidget = const Icon(Icons.cancel, color: Colors.black45,),
    this.onCancelled,
    this.suggestions = const [],
    this.buildSuggestion,
    SearchBarStyle searchBarStyle,
    this.crossAxisCount = 1,
    this.shrinkWrap = false,
    this.indexedScaledTileBuilder,
    this.scrollDirection = Axis.vertical,
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
    this.listPadding = const EdgeInsets.all(0),
    this.searchBarPadding = const EdgeInsets.all(0),
    this.headerPadding = const EdgeInsets.all(0),
    this.trailingIcon,
    this.widthRatio = 0.8,
    this.searchQueryController,
    this.onHelp,
  }) : searchBarStyle = searchBarStyle ?? SearchBarStyle(), super(key: key);

  @override
  _SearchBarState createState() => _SearchBarState<T>();
}

class _SearchBarState<T> extends State<SearchBar<T>>
    with TickerProviderStateMixin, _ControllerListener<T> {
  bool _loading = false;
  Widget _error;
  TextEditingController _searchQueryController;
  Timer _debounce;
  bool _animate = false;
  List<T> _list = [];
  SearchBarController searchBarController;
  FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    searchBarController =
        widget.searchBarController ?? SearchBarController<T>();
    _searchQueryController =
        widget.searchQueryController ?? TextEditingController();
    searchBarController.setListener(this);
  }

  @override
  void dispose() {
    if (widget.searchQueryController == null) {
      _searchQueryController.dispose();
    }
    super.dispose();
  }

  @override
  void onListChanged(List<T> items) {
    setState(() {
      _loading = false;
      _list = items;
    });
  }

  @override
  void onLoading() {
    setState(() {
      _loading = true;
      _error = null;
      _animate = true;
    });
  }

  @override
  void onClear() {
    _cancel();
  }

  @override
  void onError(Error error) {
    setState(() {
      _loading = false;
      _error = widget.onError != null ? widget.onError(error) : Text("error");
    });
  }

  _onTextChanged(String newText) async {
    if (_debounce?.isActive ?? false) {
      _debounce.cancel();
    }

    _debounce = Timer(widget.debounceDuration, () async {
      if (newText.length >= widget.minimumChars && widget.onSearch != null) {
        searchBarController._search(newText, widget.onSearch);
      } else {
        setState(() {
          _list.clear();
          _error = null;
          _loading = false;
          _animate = false;
        });
      }
    });
  }

  void _cancel() {
    if (widget.onCancelled != null) {
      widget.onCancelled();
    }

    setState(() {
      _searchQueryController.clear();
      _list.clear();
      _error = null;
      _loading = false;
      _animate = false;
    });
  }

  Widget _buildListView(
      List<T> items, Widget Function(T item, int index) builder) {
    return Padding(
      padding: widget.listPadding,
      child: StaggeredGridView.countBuilder(
        crossAxisCount: widget.crossAxisCount,
        itemCount: items.length,
        shrinkWrap: widget.shrinkWrap,
        staggeredTileBuilder:
            widget.indexedScaledTileBuilder ?? (int index) => ScaledTile.fit(1),
        scrollDirection: widget.scrollDirection,
        mainAxisSpacing: widget.mainAxisSpacing,
        crossAxisSpacing: widget.crossAxisSpacing,
        addAutomaticKeepAlives: true,
        itemBuilder: (BuildContext context, int index) {
          return builder(items[index], index);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_error != null) {
      return _error;
    } else if (_loading) {
      return widget.loader;
    } else if (_searchQueryController.text.length < widget.minimumChars) {
      if (widget.placeHolder != null) return widget.placeHolder;
      return _buildListView(
          widget.suggestions, widget.buildSuggestion ?? widget.onItemFound);
    } else if (_list.isNotEmpty) {
      return _buildListView(_list, widget.onItemFound);
    } else {
      return widget.emptyWidget;
    }
  }

  @override
  Widget build(BuildContext context) {
    final widthMax = MediaQuery.of(context).size.width;
    var _suffixWidget;

    if (_animate) {
      _suffixWidget = Container(
        key: ValueKey<int>(0),
        width: MediaQuery.of(context).size.width * .2,
        color: Colors.transparent,
        child: widget.cancellationWidget,
      );
    } else {
      _suffixWidget = Container(
        key: ValueKey<int>(1),
        width: widget.onHelp != null ? MediaQuery.of(context).size.width * .2 : 0,
        color: Colors.transparent,
        child: widget.onHelp != null ? Icon(Icons.help_outline_rounded, color: Colors.black45) : null,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: widget.searchBarPadding,
          child: Container(
            height: 80,
            constraints: BoxConstraints(maxHeight: 80),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Flexible(
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    width: widget.trailingIcon != null ? widget.widthRatio * widthMax : widthMax,
                    decoration: BoxDecoration(
                      borderRadius: widget.searchBarStyle.borderRadius,
                      color: widget.searchBarStyle.backgroundColor,
                      border: widget.searchBarStyle.border,
                    ),
                    child: Padding(
                      padding: widget.searchBarStyle.padding,
                      child: Theme(
                        child: TextField(
                          focusNode: _focusNode,
                          controller: _searchQueryController,
                          onChanged: _onTextChanged,
                          style: widget.textStyle,
                          decoration: InputDecoration(
                            icon: Padding(
                              padding: EdgeInsetsDirectional.only(start: 20.0),
                              child: widget.icon
                            ),
                            border: InputBorder.none,
                            hintText: widget.hintText,
                            hintStyle: widget.hintStyle,
                            suffixIcon: Material(
                              child: InkWell(
                                onTap: widget.onHelp != null
                                    ? (_animate ? _cancel : () {
                                      _focusNode.unfocus();
                                      _focusNode.canRequestFocus = false;
                                      widget.onHelp();
                                      _focusNode.canRequestFocus = true;
                                }) : _cancel,
                                // child: AnimatedOpacity(
                                //   opacity: _animate ? 1.0 : 0,
                                //   curve: Curves.easeIn,
                                //   duration: Duration(milliseconds: _animate ? 1000 : 0),
                                //   child: AnimatedContainer(
                                //     duration: Duration(milliseconds: 200),
                                //     width:
                                //     _animate ? MediaQuery.of(context).size.width * .2 : 0,
                                //     child: Container(
                                //       color: Colors.transparent,
                                //       child: widget.cancellationWidget,
                                //     ),
                                //   ),
                                // ),
                                child: AnimatedSwitcher(
                                  duration: Duration(milliseconds: 200),
                                  child: _suffixWidget,
                                ),
                              ),
                            ),
                          ),
                        ),
                        data: Theme.of(context).copyWith(
                          primaryColor: widget.iconActiveColor,
                        ),
                      ),
                    ),
                  ),
                ),
                widget.trailingIcon != null ? widget.trailingIcon : Container(width: 0.0)
              ],
            ),
          ),
        ),
        Padding(
          padding: widget.headerPadding,
          child: widget.header ?? Container(),
        ),
        Expanded(
          child: _buildContent(context),
        ),
      ],
    );
  }
}
