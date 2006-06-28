Localization.define('fr', 'Français') do |l| 

  # trackers
  l.store 'Bug', 'Anomalie'
  l.store 'Feature request', 'Evolution'
  l.store 'Support request', 'Assistance'
  # issue statuses
  l.store 'New', 'Nouveau'
  l.store 'Assigned', 'Assignée'
  l.store 'Resolved', 'Résolue'
  l.store 'Closed', 'Fermée'
  l.store 'Rejected', 'Rejetée'
  l.store 'Feedback', 'Commentaire'  

  # issue priorities
  l.store 'Issue priorities', 'Priorités des demandes'
  l.store 'Low', 'Bas'
  l.store 'Normal', 'Normal'
  l.store 'High', 'Haut'
  l.store 'Urgent', 'Urgent'
  l.store 'Immediate', 'Immédiat'
  # document categories
  l.store 'Document categories', 'Catégories de documents'
  l.store 'Uncategorized', 'Sans catégorie'
  l.store 'User documentation', 'Documentation utilisateur'
  l.store 'Technical documentation', 'Documentation technique'  
  # dates  
  l.store '(date)', lambda { |t| t.strftime('%d/%m/%Y') }  
  l.store '(time)', lambda { |t| t.strftime('%d/%m/%Y %H:%M') }  
 
  # ./script/../config/../app/views/account/login.rhtml

  # ./script/../config/../app/views/account/my_account.rhtml
  l.store 'My account', 'Mon compte'
  l.store 'Login', 'Identifiant'
  l.store 'Created on', 'Crée le'
  l.store 'Last update', 'Mis à jour'
  l.store 'Information', 'Informations'
  l.store 'Firstname', 'Prénom'
  l.store 'Lastname', 'Nom'
  l.store 'Mail', 'Mail'
  l.store 'Language', 'Langue'
  l.store 'Mail notifications', 'Notifications par mail'
  l.store 'Save', 'Valider'
  l.store 'Password', 'Mot de passe'
  l.store 'New password', 'Nouveau mot de passe'
  l.store 'Confirmation', 'Confirmation'

  # ./script/../config/../app/views/account/my_page.rhtml
  l.store 'My page', 'Ma page'
  l.store 'Welcome', 'Bienvenue'
  l.store 'Last login', 'Dernière connexion'
  l.store 'Reported issues', 'Demandes soumises'
  l.store 'Assigned to me', 'Demandes qui me sont assignées'

  # ./script/../config/../app/views/account/show.rhtml
  l.store 'Registered on', 'Inscrit le'
  l.store 'Projects', 'Projets'
  l.store 'Activity', 'Activité'

  # ./script/../config/../app/views/admin/index.rhtml
  l.store 'Administration', 'Administration'
  l.store 'Users', 'Utilisateurs'
  l.store 'Roles and permissions', 'Rôles et permissions'
  l.store 'Trackers', 'Trackers'
  l.store 'Custom fields', 'Champs personnalisés'
  l.store 'Issue Statuses', 'Statuts des demandes'
  l.store 'Workflow', 'Workflow'
  l.store 'Enumerations', 'Listes de valeurs'

  # ./script/../config/../app/views/admin/info.rhtml
  l.store 'Version', 'Version'
  l.store 'Database', 'Base de données'

  # ./script/../config/../app/views/admin/mail_options.rhtml
  l.store 'Select actions for which mail notification should be enabled.', 'Sélectionner les actions pour lesquelles la notification par mail doit être activée.'
  l.store 'Check all', 'Cocher tout'
  l.store 'Uncheck all', 'Décocher tout'

  # ./script/../config/../app/views/admin/projects.rhtml
  l.store 'Project', 'Projet'
  l.store 'Description', 'Description'
  l.store 'Public', 'Public'
  l.store 'Delete', 'Supprimer'
  l.store 'Previous', 'Précédent'
  l.store 'Next', 'Suivant'

  # ./script/../config/../app/views/custom_fields/edit.rhtml
  l.store 'Custom field', 'Champ personnalisé'

  # ./script/../config/../app/views/custom_fields/list.rhtml
  l.store 'Name', 'Nom'
  l.store 'Type', 'Type'
  l.store 'Required', 'Obligatoire'
  l.store 'For all projects', 'Pour tous les projets'
  l.store 'Used by', 'Utilisé par'

  # ./script/../config/../app/views/custom_fields/new.rhtml
  l.store 'New custom field', 'Nouveau champ personnalisé'
  l.store 'Create', 'Créer'

  # ./script/../config/../app/views/custom_fields/_form.rhtml
  l.store '0 means no restriction', '0 pour aucune restriction'
  l.store 'Regular expression pattern', 'Expression régulière'
  l.store 'Possible values', 'Valeurs possibles'

  # ./script/../config/../app/views/documents/edit.rhtml
  l.store 'Document', 'Document'

  # ./script/../config/../app/views/documents/show.rhtml
  l.store 'Category', 'Catégorie'
  l.store 'Edit', 'Modifier'
  l.store 'download', 'téléchargement'
  l.store 'Add file', 'Ajouter le fichier'
  l.store 'Add', 'Ajouter'

  # ./script/../config/../app/views/documents/_form.rhtml
  l.store 'Title', 'Titre'

  # ./script/../config/../app/views/enumerations/edit.rhtml

  # ./script/../config/../app/views/enumerations/list.rhtml

  # ./script/../config/../app/views/enumerations/new.rhtml
  l.store 'New enumeration', 'Nouvelle valeur'

  # ./script/../config/../app/views/enumerations/_form.rhtml

  # ./script/../config/../app/views/issues/change_status.rhtml
  l.store 'Issue', 'Demande'
  l.store 'New status', 'Nouveau statut'
  l.store 'Assigned to', 'Assigné à'
  l.store 'Fixed in version', 'Version corrigée'
  l.store 'Notes', 'Remarques'

  # ./script/../config/../app/views/issues/edit.rhtml
  l.store 'Status', 'Statut'
  l.store 'Tracker', 'Tracker'
  l.store 'Priority', 'Priorité'
  l.store 'Subject', 'Sujet'

  # ./script/../config/../app/views/issues/show.rhtml
  l.store 'Author', 'Auteur'
  l.store 'Change status', 'Changer le statut'
  l.store 'History', 'Historique'
  l.store 'Attachments', 'Fichiers'
  l.store 'Update...', 'Changer...'

  # ./script/../config/../app/views/issues/_list_simple.rhtml
  l.store 'No issue', 'Aucune demande'

  # ./script/../config/../app/views/issue_categories/edit.rhtml

  # ./script/../config/../app/views/issue_categories/_form.rhtml

  # ./script/../config/../app/views/issue_statuses/edit.rhtml
  l.store 'Issue status', 'Statut de demande'

  # ./script/../config/../app/views/issue_statuses/list.rhtml
  l.store 'Issue statuses', 'Statuts de demande'
  l.store 'Default status', 'Statut par défaut'
  l.store 'Issue closed', 'Demande fermée'
  l.store 'Color', 'Couleur'

  # ./script/../config/../app/views/issue_statuses/new.rhtml
  l.store 'New issue status', 'Nouveau statut'

  # ./script/../config/../app/views/issue_statuses/_form.rhtml

  # ./script/../config/../app/views/layouts/base.rhtml
  l.store 'Home', 'Accueil'
  l.store 'Help', 'Aide'
  l.store 'Log in', 'Connexion'
  l.store 'Logout', 'Déconnexion'
  l.store 'Overview', 'Aperçu'
  l.store 'Issues', 'Demandes'
  l.store 'Reports', 'Rapports'
  l.store 'News', 'Annonces'
  l.store 'Change log', 'Historique'
  l.store 'Documents', 'Documents'
  l.store 'Members', 'Membres'
  l.store 'Files', 'Fichiers'
  l.store 'Settings', 'Configuration'
  l.store 'My projects', 'Mes projets'
  l.store 'Logged as', 'Connecté en tant que'

  # ./script/../config/../app/views/mailer/issue_add.rhtml

  # ./script/../config/../app/views/mailer/issue_change_status.rhtml

  # ./script/../config/../app/views/mailer/_issue.rhtml

  # ./script/../config/../app/views/news/edit.rhtml

  # ./script/../config/../app/views/news/show.rhtml
  l.store 'Summary', 'Résumé'
  l.store 'By', 'Par'
  l.store 'Date', 'Date'

  # ./script/../config/../app/views/news/_form.rhtml

  # ./script/../config/../app/views/projects/add.rhtml
  l.store 'New project', 'Nouveau projet'

  # ./script/../config/../app/views/projects/add_document.rhtml
  l.store 'New document', 'Nouveau document'
  l.store 'File', 'Fichier'

  # ./script/../config/../app/views/projects/add_issue.rhtml
  l.store 'New issue', 'Nouvelle demande'
  l.store 'Attachment', 'Fichier'

  # ./script/../config/../app/views/projects/add_news.rhtml

  # ./script/../config/../app/views/projects/add_version.rhtml
  l.store 'New version', 'Nouvelle version'

  # ./script/../config/../app/views/projects/changelog.rhtml

  # ./script/../config/../app/views/projects/destroy.rhtml
  l.store 'Are you sure you want to delete project', 'Êtes-vous sûr de vouloir supprimer le projet'

  # ./script/../config/../app/views/projects/list.rhtml
  l.store 'Public projects', 'Projets publics'

  # ./script/../config/../app/views/projects/list_documents.rhtml
  l.store 'Desciption', 'Description'

  # ./script/../config/../app/views/projects/list_files.rhtml
  l.store 'Files', 'Fichiers'
  l.store 'New file', 'Nouveau fichier'
  
  # ./script/../config/../app/views/projects/list_issues.rhtml
  l.store 'Apply filter', 'Appliquer'
  l.store 'Reset', 'Annuler'
  l.store 'Report an issue', 'Nouvelle demande'

  # ./script/../config/../app/views/projects/list_members.rhtml
  l.store 'Project members', 'Membres du projet'

  # ./script/../config/../app/views/projects/list_news.rhtml
  l.store 'Read...', 'Lire...'

  # ./script/../config/../app/views/projects/settings.rhtml
  l.store 'New member', 'Nouveau membre'
  l.store 'Versions', 'Versions'
  l.store 'New version...', 'Nouvelle version...'
  l.store 'Issue categories', 'Catégories des demandes'
  l.store 'New category', 'Nouvelle catégorie'

  # ./script/../config/../app/views/projects/show.rhtml
  l.store 'Homepage', 'Site web'
  l.store 'open', 'ouverte(s)'
  l.store 'View all issues', 'Voir toutes les demandes'
  l.store 'View all news', 'Voir toutes les annonces'
  l.store 'Latest news', 'Dernières annonces'

  # ./script/../config/../app/views/projects/_form.rhtml

  # ./script/../config/../app/views/reports/issue_report.rhtml
  l.store 'Issues by tracker', 'Demandes par tracker'
  l.store 'Issues by priority', 'Demandes par priorité'
  l.store 'Issues by category', 'Demandes par catégorie'

  # ./script/../config/../app/views/reports/_simple.rhtml
  l.store 'Open', 'Ouverte'
  l.store 'Total', 'Total'

  # ./script/../config/../app/views/roles/edit.rhtml
  l.store 'Role', 'Rôle'

  # ./script/../config/../app/views/roles/list.rhtml
  l.store 'Roles', 'Rôles'

  # ./script/../config/../app/views/roles/new.rhtml
  l.store 'New role', 'Nouveau rôle'

  # ./script/../config/../app/views/roles/workflow.rhtml
  l.store 'Workflow setup', 'Configuration du workflow'
  l.store 'Select a workflow to edit', 'Sélectionner un workflow à mettre à jour'
  l.store 'New statuses allowed', 'Nouveaux statuts autorisés'

  # ./script/../config/../app/views/roles/_form.rhtml
  l.store 'Permissions', 'Permissions'

  # ./script/../config/../app/views/trackers/edit.rhtml

  # ./script/../config/../app/views/trackers/list.rhtml
  l.store 'View issues in change log', 'Demandes affichées dans l\'historique'

  # ./script/../config/../app/views/trackers/new.rhtml
  l.store 'New tracker', 'Nouveau tracker'

  # ./script/../config/../app/views/trackers/_form.rhtml

  # ./script/../config/../app/views/users/add.rhtml
  l.store 'New user', 'Nouvel utilisateur'

  # ./script/../config/../app/views/users/edit.rhtml
  l.store 'User', 'Utilisateur'

  # ./script/../config/../app/views/users/list.rhtml
  l.store 'Admin', 'Admin'
  l.store 'Locked', 'Verrouillé'

  # ./script/../config/../app/views/users/_form.rhtml
  l.store 'Administrator', 'Administrateur'

  # ./script/../config/../app/views/versions/edit.rhtml

  # ./script/../config/../app/views/versions/_form.rhtml

  # ./script/../config/../app/views/welcome/index.rhtml
  

end 
