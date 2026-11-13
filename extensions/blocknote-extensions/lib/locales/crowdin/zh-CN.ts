export const en = {
  translation: {
    'slashMenu': {
      'title': 'Link existing work package',
      'subtext': 'Add a dynamic link to a single work package',
      'create': {
        'title': "创建新工作包",
        'subtext': 'Create a work package and link it here'
      },
      'aliases': {
        'workpackage': 'workpackage',
        'work package': "工作包",
        'wp': 'wp',
        'link': "链接",
        'create': "创建",
        'attribute': "属性"
      },
      'attribute': {
        'title': 'Work package attribute',
        'subtext': 'Insert a live attribute or custom field'
      }
    },
    'formattingToolbar': {
      'createWorkPackage': "创建工作包"
    },
    'createWorkPackage': {
      'title': "创建新工作包",
      'close': "已关闭",
      'cancel': "取消",
      'create': "创建",
      'creating': 'Creating…',
      'selectPlaceholder': 'Please select…',
      'searchPlaceholder': 'Type to search…',
      'loading': "正在加载…",
      'noResults': "无结果",
      'filterBy': 'Filter the list',
      'allValues': "所有",
      'favorites': "收藏",
      'clear': "清除",
      'deselect': 'Remove selection',
      'removeValue': 'Remove {{value}}',
      'openOptions': "显示选项",
      'closeOptions': "隐藏选项",
      'subjectPlaceholder': "在此处输入标题",
      'subjectClipped': 'The selected text was too long and has been shortened to the first {{limit}} characters.',
      'projectPlaceholder': 'Select a project…',
      'loadFailed': 'The work package form could not be loaded: {{message}}',
      'notAllowed': 'You are not allowed to create work packages.',
      'validationFailed': 'Please correct the highlighted fields below.',
      'requiredField': 'This field is required.',
      'notANumber': 'Please enter a number.',
      'notAWholeNumber': 'Please enter a whole number, without a decimal separator.',
      'unsupportedField': '"{{field}}" cannot be set here.',
      'unsupportedRequired': 'This work package requires a field that cannot be set here.',
      'createInOpenProject': 'Create it in OpenProject'
    },
    'search': {
      'label': 'Link existing work package',
      'placeholder': 'Search by work package ID or subject',
      'dropdownAriaLabel': 'Work package search results',
      'noResults': "无结果",
      'error': 'Error. Unable to load content.',
      'createWorkPackage': "创建新工作包"
    },
    'unavailableWorkPackage': {
      'loading': {
        'header': 'Loading',
        'message': "请稍等"
      },
      'unauthorized': {
        'header': 'Linked work package unavailable',
        'message': 'You do not have permission to see this',
        'short_message': 'Work package unavailable: no permission'
      },
      'error': {
        'header': "错误",
        'message': 'Could not load work package',
        'short_message': 'Unavailable: error'
      }
    },
    'options': {
      'openInNewTab': 'Open in new tab',
      'open': "打开",
      'changeSize': 'Change size',
      'changeSizeAriaLabel': 'Change size: {{size}}',
      'menuAriaLabel': 'Options for work package {{id}}',
      'selectedAnnouncement': '{{description}}. Press Enter to open its options.',
      'remove': "移除",
      'removeAriaLabel': "移除工作包",
      'openAriaLabel': 'Open work package {{id}} in new tab',
      'inlineSizeLabel': 'Inline size',
      'blockSizeLabel': 'Block size',
      'chipAriaLabel': 'Work package {{id}}'
    },
    'preview': {
      'showAriaLabel': 'Show details of work package {{id}}'
    },
    'sizes': {
      'xxs': {
        'label': 'Tiny',
        'desc': "标识符"
      },
      'xs': {
        'label': 'Compact',
        'desc': 'Type, Identifier, Subject'
      },
      's': {
        'label': "常规",
        'desc': 'Status, Type, Identifier, Subject'
      },
      'm': {
        'label': 'Compact card',
        'desc': 'Status, Type, Identifier, Subject'
      },
      'l': {
        'label': 'Regular card',
        'desc': 'Identifier, Subject, Type, Status, Parent, Project'
      },
      'xl': {
        'label': 'Full card',
        'desc': 'Identifier, Subject, Type, Status, Parent, Project, Description'
      }
    },
    'hashMenu': {
      'typeToSearch': 'Type to search work packages…'
    },
    'spinner': {
      'ariaLabel': 'Loading'
    },
    'workPackageAttribute': {
      'missing': '{{attribute}} unavailable',
      'yes': "是",
      'no': "否",
      'days_one': '{{count}} day',
      'days_other': '{{count}} days',
      'display': {
        'label': "标签",
        'value': "值",
        'both': 'Label + value'
      },
      'dialog': {
        'title': 'Insert work package attribute',
        'workPackage': "工作包",
        'attribute': "属性",
        'attributePlaceholder': 'Select an attribute…',
        'attributeDisabled': 'Select a work package first',
        'attributeLoading': 'Loading attributes…',
        'attributeUnavailable': 'Attributes unavailable',
        'loadFailed': 'The attributes of {{id}} could not be loaded.',
        'retry': "重试",
        'prefilled': 'Prefilled with your last selection',
        'notAvailable': '"{{attribute}}" is not available on {{id}}. Choose another attribute.',
        'show': "显示",
        'preview': "预览",
        'previewEmpty': 'Choose a work package and an attribute',
        'insert': "插入"
      }
    }
  }
};