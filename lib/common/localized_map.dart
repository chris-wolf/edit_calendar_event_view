const localizedMap = {
  'read_only_event': {'en': 'Read only event', 'de': 'Nur-Lese-Ereignis'},
  'add_event': {'en': 'Add event', 'de': 'Ereignis hinzufügen'},
  'edit_event': {'en': 'Edit event', 'de': 'Ereignis bearbeiten'},
  'delete': {'en': 'Delete', 'de': 'Löschen'},
  'Save': {'en': 'Save', 'de': 'Speichern'},
  'event_title': {'en': 'Title', 'de': 'Titel'},
  'event_description': {'en': 'Descripition', 'de': 'Beschreibung'},
  'all_day': {'en': 'All', 'de': 'Alle'},
  'event_start': {'en': 'Start', 'de': 'Starten'},
  'event_end': {'en': 'End', 'de': 'Ende'},
  'repeat_once': {'en': 'Once', 'de': 'Einmal'},
  'select_calendar': {'en': 'Select calendar', 'de': 'Kalender auswählen'},
  'event_color': {'en': 'Event color', 'de': 'Ereignisfarbe'},
  'not_set': {'en': 'Not set', 'de': 'Nicht festgelegt'},
  'remove_reminder': {'en': 'Remove reminder', 'de': 'Erinnerung entfernen'},
  'add_reminder': {'en': 'Add reminder', 'de': 'Erinnerung hinzufügen'},
  'event_location': {'en': 'Location', 'de': 'Standort'},
  'event_website': {'en': 'Website', 'de': 'Webseite'},
  'set_status': {'en': 'Set status', 'de': 'Status festlegen'},
  'add_attendee': {'en': 'Add attendee', 'de': 'Teilnehmer hinzufügen'},
  'custom': {'en': 'Custom', 'de': 'Benutzerdefiniert'},
  's_before': {'en': '%s before', 'de': '%s davor'},
  'every': {'en': 'Every', 'de': 'Jeder'},
  'day': {'en': 'day', 'de': 'Tag'},
  'days': {'en': 'days', 'de': 'Tage'},
  'week': {'en': 'week', 'de': 'Woche'},
  'weeks': {'en': 'weeks', 'de': 'Wochen'},
  'month': {'en': 'month', 'de': 'Monat'},
  'months': {'en': 'months', 'de': 'Monate'},
  'year': {'en': 'year', 'de': 'Jahr'},
  'years': {'en': 'years', 'de': 'Jahre'},
  'on_day_s': {'en': 'On day %s', 'de': 'Am Tag %s'},
  '1_week': {'en': '1st week', 'de': '1. Woche'},
  '2_week': {'en': '2nd week', 'de': '2. Woche'},
  '3_week': {'en': '3th week', 'de': '3. Woche'},
  '4_week': {'en': '4th week', 'de': '4. Woche'},
  '5_week': {'en': 'Last week', 'de': 'Letzte Woche'},
  'for_s': {'en': 'for %s', 'de': 'für %s'},
  'in_s': {'en': 'in %s', 'de': 'in %s'},
  'for_n_events': {'en': 'for %d events', 'de': 'für %d Veranstaltungen'},
  'until_s': {'en': 'until %s', 'de': 'bis %s'},
  'on_s': {'en': 'on %s', 'de': '\"auf „%s“\"'},
  'n_minutes': {'en': '%d minutes', 'de': '%d Minuten'},
  'n_hours': {'en': '%d hours', 'de': '%d Stunden'},
  'n_days': {'en': '%d days', 'de': '%d Tage'},
  'n_weeks': {'en': '%d weeks', 'de': '%d Wochen'},
  '1_minutes': {'en': '1 minute', 'de': '1 Minute'},
  '1_hours': {'en': '1 hour', 'de': '1 Stunde'},
  '1_days': {'en': '1 day', 'de': '1 Tag'},
  '1_weeks': {'en': '1 week', 'de': '1 Woche'},
  'add': {'en': 'Add', 'de': 'Hinzufügen'},
  'custom_recurrency_rule': {'en': 'Custom recurrence rule', 'de': 'Benutzerdefinierte Wiederholungsregel'},
  'repeat_every': {'en': 'Repeat every', 'de': 'Wiederhole jeden'},
  'day_of_month': {'en': 'Day of month', 'de': 'Tag des Monats'},
  'week_of_month': {'en': 'Week of month', 'de': 'Woche des Monats'},
  'select_day_of_the_week': {'en': 'Select day of the week', 'de': 'Wochentag auswählen'},
  'select_day_of_the_month': {'en': 'Select day of the month', 'de': 'Wählen Sie den Tag des Monats'},
  'on_week_of_the_month': {'en': 'On following weeks of the month', 'de': 'In den folgenden Wochen des Monats'},
  'only_for_these_months': {'en': 'Only for these months', 'de': 'Nur für diese Monate'},
  'ends': {'en': 'Ends', 'de': 'Endet'},
  'never': {'en': 'Never', 'de': 'Nie'},
  'NONE': {'en': '', 'de': ''},
  'CONFIRMED': {'en': 'Confirmed', 'de': 'Bestätigt'},
  'CANCELED': {'en': 'Canceled', 'de': 'Abgesagt'},
  'TENTATIVE': {'en': 'Tentative', 'de': 'Vorläufig'},
  'FREE': {'en': 'Free', 'de': 'Kostenlos'},
  'BUSY': {'en': 'Busy', 'de': 'Beschäftigt'},
  'UNAVAILABLE': {'en': 'Unavailable', 'de': 'Nicht verfügbar'},
  'name': {'en': 'Name', 'de': 'Name'},
  'edit_attendee': {'en': 'Edit attendee', 'de': 'Teilnehmer bearbeiten'},
  'add_an_attendee': {'en': 'Add an attendee', 'de': 'Einen Teilnehmer hinzufügen'},
  'please_enter_a_name': {'en': 'Please enter a name', 'de': 'Bitte geben Sie einen Namen ein'},
  'enter_valid_email': {'en': 'Please enter a valid email address', 'de': 'Bitte geben Sie eine gültige E-Mail-Adresse ein'},
  'email_address': {'en': 'Email Address', 'de': 'E-Mail-Adresse'},
  'role': {'en': 'Role', 'de': 'Rolle'},
  'view_or_edit_attendance_details': {'en': 'View / edit attendance details', 'de': 'Ansicht / Bearbeitung der Teilnahmedetails'},
  'attendee_status': {'en': 'Attendee status', 'de': 'Teilnahmestatus'},
  'REQUIRED': {'en': 'Required', 'de': 'Erforderlich'},
  'OPTIONAL': {'en': 'Optional', 'de': 'Optional'},
  'RESOURCE': {'en': 'Resource', 'de': 'Ressource'},
  'ACCEPTED': {'en': 'Accepted', 'de': 'Angenommen'},
  'DECLINED': {'en': 'Declined', 'de': 'Abgelehnt'},
  'INVITED': {'en': 'Invited', 'de': 'Eingeladen'},
};
