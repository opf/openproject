export const en = {
  translation: {
    'slashMenu': {
      'title': "Ligue o pacote de trabalho existente",
      'subtext': "Adicione uma ligação dinâmica a um único pacote de trabalho",
      'create': {
        'title': "Criar novo pacote de trabalho",
        'subtext': 'Create a work package and link it here'
      },
      'aliases': {
        'workpackage': "pacote de trabalho",
        'work package': "pacote de trabalho",
        'wp': 'wp',
        'link': 'link',
        'create': "criar",
        'attribute': "atributo"
      },
      'attribute': {
        'title': 'Work package attribute',
        'subtext': 'Insert a live attribute or custom field'
      }
    },
    'formattingToolbar': {
      'createWorkPackage': "Criar pacote de trabalho"
    },
    'createWorkPackage': {
      'title': "Criar novo pacote de trabalho",
      'close': "Fechar",
      'cancel': "Cancelar",
      'create': "Criar",
      'creating': 'Creating…',
      'selectPlaceholder': 'Please select…',
      'searchPlaceholder': 'Type to search…',
      'loading': "A carregar…",
      'noResults': "Sem resultados",
      'filterBy': 'Filter the list',
      'allValues': "Tudo",
      'favorites': "Favoritos",
      'clear': "Limpar",
      'deselect': 'Remove selection',
      'removeValue': 'Remove {{value}}',
      'openOptions': "Mostrar opções",
      'closeOptions': "Ocultar opções",
      'subjectPlaceholder': "Introduza aqui o assunto",
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
      'label': "Ligue o pacote de trabalho existente",
      'placeholder': "Pesquise por ID do pacote de trabalho ou assunto",
      'dropdownAriaLabel': "Resultados da pesquisa de pacotes de trabalho",
      'noResults': "Sem resultados",
      'error': 'Error. Unable to load content.',
      'createWorkPackage': "Criar novo pacote de trabalho"
    },
    'unavailableWorkPackage': {
      'loading': {
        'header': "A carregar",
        'message': "Aguarde, por favor"
      },
      'unauthorized': {
        'header': "Pacote de trabalho associado não disponível",
        'message': "Você não tem permissão para ver isto",
        'short_message': 'Work package unavailable: no permission'
      },
      'error': {
        'header': "Erro",
        'message': "Não foi possível carregar o pacote de trabalho",
        'short_message': 'Unavailable: error'
      }
    },
    'options': {
      'openInNewTab': 'Open in new tab',
      'open': "Aberta",
      'changeSize': 'Change size',
      'changeSizeAriaLabel': 'Change size: {{size}}',
      'menuAriaLabel': 'Options for work package {{id}}',
      'selectedAnnouncement': '{{description}}. Press Enter to open its options.',
      'remove': "Remover",
      'removeAriaLabel': "Remover pacote de trabalho",
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
        'desc': "Identificador"
      },
      'xs': {
        'label': 'Compact',
        'desc': 'Type, Identifier, Subject'
      },
      's': {
        'label': "Normal",
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
      'ariaLabel': "A carregar"
    },
    'workPackageAttribute': {
      'missing': '{{attribute}} unavailable',
      'yes': "Sim",
      'no': "Não",
      'days_one': '{{count}} day',
      'days_other': '{{count}} days',
      'display': {
        'label': "Etiqueta",
        'value': "Valor",
        'both': 'Label + value'
      },
      'dialog': {
        'title': 'Insert work package attribute',
        'workPackage': "Pacote de trabalho",
        'attribute': "Atributo",
        'attributePlaceholder': 'Select an attribute…',
        'attributeDisabled': 'Select a work package first',
        'attributeLoading': 'Loading attributes…',
        'attributeUnavailable': 'Attributes unavailable',
        'loadFailed': 'The attributes of {{id}} could not be loaded.',
        'retry': "Tentar novamente",
        'prefilled': 'Prefilled with your last selection',
        'notAvailable': '"{{attribute}}" is not available on {{id}}. Choose another attribute.',
        'show': "Mostrar",
        'preview': "Pré-visualização",
        'previewEmpty': 'Choose a work package and an attribute',
        'insert': "Inserir"
      }
    }
  }
};