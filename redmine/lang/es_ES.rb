Localization.define('es', 'Español') do |l| 

  # trackers
  l.store 'Bug', 'Anomalía'
  l.store 'Feature request', 'Evolución'
  l.store 'Support request', 'Asistencia'
  # issue statuses
  l.store 'New', 'Nuevo'
  l.store 'Assigned', 'Asignada'
  l.store 'Resolved', 'Resuelta'
  l.store 'Closed', 'Cerrada'
  l.store 'Rejected', 'Rechazada'
  l.store 'Feedback', 'Comentario'  

  # issue priorities
  l.store 'Issue priorities', 'Prioridad de las peticiones'
  l.store 'Low', 'Bajo'
  l.store 'Normal', 'Normal'
  l.store 'High', 'Alto'
  l.store 'Urgent', 'Urgente'
  l.store 'Immediate', 'Ahora'
  # document categories
  l.store 'Document categories', 'Categorías del documento'
  l.store 'Uncategorized', 'Sin categorías '
  l.store 'User documentation', 'Documentación del usuario'
  l.store 'Technical documentation', 'Documentación tecnica'  
  # dates  
  l.store '(date)', lambda { |t| t.strftime('%d/%m/%Y') }  
  l.store '(time)', lambda { |t| t.strftime('%d/%m/%Y %H:%M') }  
   
  # ./script/../config/../app/views/account/login.rhtml

  # ./script/../config/../app/views/account/my_account.rhtml
  l.store 'My account', 'Mi cuenta'
  l.store 'Login', 'Identificador'
  l.store 'Created on', 'Creado el'
  l.store 'Last update', 'Actualizado'
  l.store 'Information', 'Informaciones'
  l.store 'Firstname', 'Nombre'
  l.store 'Lastname', 'Apellido'
  l.store 'Mail', 'Mail'
  l.store 'Language', 'Lengua'
  l.store 'Mail notifications', 'Notificación por mail'
  l.store 'Save', 'Validar'
  l.store 'Password', 'Contraseña'
  l.store 'New password', 'Nueva contraseña'
  l.store 'Confirmation', 'Confirmación'

  # ./script/../config/../app/views/account/my_page.rhtml
  l.store 'My page', 'Mi página'
  l.store 'Welcome', 'Bienvenido'
  l.store 'Last login', 'Última conexión'
  l.store 'Reported issues', 'Peticiones registradas'
  l.store 'Assigned to me', 'Peticiones que me están asignadas'

  # ./script/../config/../app/views/account/show.rhtml
  l.store 'Registered on', 'Inscrito el'
  l.store 'Projects', 'Proyectos'
  l.store 'Activity', 'Actividad'

  # ./script/../config/../app/views/admin/index.rhtml
  l.store 'Administration', 'Administración'
  l.store 'Users', 'Usuarios'
  l.store 'Roles and permissions', 'Papeles y permisos'
  l.store 'Trackers', 'Trackers'
  l.store 'Custom fields', 'Campos personalizados'
  l.store 'Issue Statuses', 'Estatutos de las peticiones'
  l.store 'Workflow', 'Workflow'
  l.store 'Enumerations', 'Listas de valores'

  # ./script/../config/../app/views/admin/info.rhtml
  l.store 'Version', 'Versión'
  l.store 'Database', 'Base de datos'

  # ./script/../config/../app/views/admin/mail_options.rhtml
  l.store 'Select actions for which mail notification should be enabled.', 'Seleccionar las actividades que necesitan la activación de la notificación por mail.'
  l.store 'Check all', 'Seleccionar todo'
  l.store 'Uncheck all', 'No seleccionar nada'

  # ./script/../config/../app/views/admin/projects.rhtml
  l.store 'Project', 'Proyecto'
  l.store 'Description', 'Descripción'
  l.store 'Public', 'Público'
  l.store 'Delete', 'Suprimir'
  l.store 'Previous', 'Precedente'
  l.store 'Next', 'Próximo'

  # ./script/../config/../app/views/custom_fields/edit.rhtml
  l.store 'Custom field', 'Campo personalizado'

  # ./script/../config/../app/views/custom_fields/list.rhtml
  l.store 'Name', 'Nombre'
  l.store 'Type', 'Tipo'
  l.store 'Required', 'Obligatorio'
  l.store 'For all projects', 'Para todos los proyectos'
  l.store 'Used by', 'Utilizado por'

  # ./script/../config/../app/views/custom_fields/new.rhtml
  l.store 'New custom field', 'Nuevo campo personalizado'
  l.store 'Create', 'Crear'

  # ./script/../config/../app/views/custom_fields/_form.rhtml
  l.store '0 means no restriction', '0 para ninguna restricción'
  l.store 'Regular expression pattern', 'Expresión regular'
  l.store 'Possible values', 'Valores posibles'

  # ./script/../config/../app/views/documents/edit.rhtml
  l.store 'Document', 'Documento'

  # ./script/../config/../app/views/documents/show.rhtml
  l.store 'Category', 'Categoría'
  l.store 'Edit', 'Modificar'
  l.store 'download', 'Telecarga'
  l.store 'Add file', 'Añadir el fichero'
  l.store 'Add', 'Añadir'

  # ./script/../config/../app/views/documents/_form.rhtml
  l.store 'Title', 'Título'

  # ./script/../config/../app/views/enumerations/edit.rhtml

  # ./script/../config/../app/views/enumerations/list.rhtml

  # ./script/../config/../app/views/enumerations/new.rhtml
  l.store 'New enumeration', 'Nuevo valor'

  # ./script/../config/../app/views/enumerations/_form.rhtml

  # ./script/../config/../app/views/issues/change_status.rhtml
  l.store 'Issue', 'Petición'
  l.store 'New status', 'Nuevo estatuto'
  l.store 'Assigned to', 'Asignado a'
  l.store 'Fixed in version', 'Versión corregida'
  l.store 'Notes', 'Anotación'

  # ./script/../config/../app/views/issues/edit.rhtml
  l.store 'Status', 'Estatuto'
  l.store 'Tracker', 'Tracker'
  l.store 'Priority', 'Prioridad'
  l.store 'Subject', 'Tema'

  # ./script/../config/../app/views/issues/show.rhtml
  l.store 'Author', 'Autor'
  l.store 'Change status', 'Cambiar el estatuto'
  l.store 'History', 'Histórico'
  l.store 'Attachments', 'Ficheros'
  l.store 'Update...', 'Actualizar...'

  # ./script/../config/../app/views/issues/_list_simple.rhtml
  l.store 'No issue', 'Ninguna petición'

  # ./script/../config/../app/views/issue_categories/edit.rhtml

  # ./script/../config/../app/views/issue_categories/_form.rhtml

  # ./script/../config/../app/views/issue_statuses/edit.rhtml
  l.store 'Issue status', 'Estatuto de petición'

  # ./script/../config/../app/views/issue_statuses/list.rhtml
  l.store 'Issue statuses', 'Estatutos de la petición'
  l.store 'Default status', 'Estatuto por defecto'
  l.store 'Issue closed', 'Petición resuelta'
  l.store 'Color', 'Color'

  # ./script/../config/../app/views/issue_statuses/new.rhtml
  l.store 'New issue status', 'Nuevo estatuto'

  # ./script/../config/../app/views/issue_statuses/_form.rhtml

  # ./script/../config/../app/views/layouts/base.rhtml
  l.store 'Home', 'Acogida'
  l.store 'Help', 'Ayuda'
  l.store 'Log in', 'Conexión'
  l.store 'Logout', 'Desconexión'
  l.store 'Overview', 'Vistazo'
  l.store 'Issues', 'Peticiones'
  l.store 'Reports', 'Rapports'
  l.store 'News', 'Noticias'
  l.store 'Change log', 'Cambios'
  l.store 'Documents', 'Documentos'
  l.store 'Members', 'Miembros'
  l.store 'Files', 'Ficheros'
  l.store 'Settings', 'Configuración'
  l.store 'My projects', 'Mis proyectos'
  l.store 'Logged as', 'Conectado como'

  # ./script/../config/../app/views/mailer/issue_add.rhtml

  # ./script/../config/../app/views/mailer/issue_change_status.rhtml

  # ./script/../config/../app/views/mailer/_issue.rhtml

  # ./script/../config/../app/views/news/edit.rhtml

  # ./script/../config/../app/views/news/show.rhtml
  l.store 'Summary', 'Resumen'
  l.store 'By', 'Por'
  l.store 'Date', 'Fecha'

  # ./script/../config/../app/views/news/_form.rhtml

  # ./script/../config/../app/views/projects/add.rhtml
  l.store 'New project', 'Nuevo proyecto'

  # ./script/../config/../app/views/projects/add_document.rhtml
  l.store 'New document', 'Nuevo documento'
  l.store 'File', 'Fichero'

  # ./script/../config/../app/views/projects/add_issue.rhtml
  l.store 'New issue', 'Nueva petición'
  l.store 'Attachment', 'Fichero'

  # ./script/../config/../app/views/projects/add_news.rhtml

  # ./script/../config/../app/views/projects/add_version.rhtml
  l.store 'New version', 'Nueva versión'

  # ./script/../config/../app/views/projects/changelog.rhtml

  # ./script/../config/../app/views/projects/destroy.rhtml
  l.store 'Are you sure you want to delete project', '¿ Estás seguro de querer eliminar el proyecto ?'

  # ./script/../config/../app/views/projects/list.rhtml
  l.store 'Public projects', 'Proyectos publicos'

  # ./script/../config/../app/views/projects/list_documents.rhtml
  l.store 'Desciption', 'Descripción'

  # ./script/../config/../app/views/projects/list_files.rhtml
  l.store 'New file', 'Nuevo fichero'
  
  # ./script/../config/../app/views/projects/list_issues.rhtml
  l.store 'Apply filter', 'Aplicar'
  l.store 'Reset', 'Anular'
  l.store 'Report an issue', 'Nueva petición'

  # ./script/../config/../app/views/projects/list_members.rhtml
  l.store 'Project members', 'Miembros del proyecto'

  # ./script/../config/../app/views/projects/list_news.rhtml
  l.store 'Read...', 'Leer...'

  # ./script/../config/../app/views/projects/settings.rhtml
  l.store 'New member', 'Nuevo miembro'
  l.store 'Versions', 'Versiónes'
  l.store 'New version...', 'Nueva versión...'
  l.store 'Issue categories', 'Categorías de las peticiones'
  l.store 'New category', 'Nueva categoría'

  # ./script/../config/../app/views/projects/show.rhtml
  l.store 'Homepage', 'Sitio web'
  l.store 'open', 'abierta(s)'
  l.store 'View all issues', 'Ver todas las peticiones'
  l.store 'View all news', 'Ver todas las noticias'
  l.store 'Latest news', 'Últimas noticias'

  # ./script/../config/../app/views/projects/_form.rhtml

  # ./script/../config/../app/views/reports/issue_report.rhtml
  l.store 'Issues by tracker', 'Peticiones por tracker'
  l.store 'Issues by priority', 'Peticiones por prioridad'
  l.store 'Issues by category', 'Peticiones por categoría'

  # ./script/../config/../app/views/reports/_simple.rhtml
  l.store 'Open', 'Abierta'
  l.store 'Total', 'Total'

  # ./script/../config/../app/views/roles/edit.rhtml
  l.store 'Role', 'Papel'

  # ./script/../config/../app/views/roles/list.rhtml
  l.store 'Roles', 'Papeles'

  # ./script/../config/../app/views/roles/new.rhtml
  l.store 'New role', 'Nuevo papel'

  # ./script/../config/../app/views/roles/workflow.rhtml
  l.store 'Workflow setup', 'Configuración del workflow'
  l.store 'Select a workflow to edit', 'Seleccionar un workflow para actualizar'
  l.store 'New statuses allowed', 'Nuevos estatutos autorizados'

  # ./script/../config/../app/views/roles/_form.rhtml
  l.store 'Permissions', 'Permisos'

  # ./script/../config/../app/views/trackers/edit.rhtml

  # ./script/../config/../app/views/trackers/list.rhtml
  l.store 'View issues in change log', 'Consultar las peticiones en el histórico'
  l.store 'New tracker', 'Nuevo tracker'
  
  # ./script/../config/../app/views/trackers/new.rhtml

  # ./script/../config/../app/views/trackers/_form.rhtml

  # ./script/../config/../app/views/users/add.rhtml
  l.store 'New user', 'Nuevo usuario'

  # ./script/../config/../app/views/users/edit.rhtml
  l.store 'User', 'Usuario'

  # ./script/../config/../app/views/users/list.rhtml
  l.store 'Admin', 'Admin'
  l.store 'Locked', 'Cerrado'

  # ./script/../config/../app/views/users/_form.rhtml
  l.store 'Administrator', 'Administrador'

  # ./script/../config/../app/views/versions/edit.rhtml

  # ./script/../config/../app/views/versions/_form.rhtml

  # ./script/../config/../app/views/welcome/index.rhtml
  

end 
