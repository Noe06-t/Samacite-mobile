/// Normalise une valeur de statut de signalement en une forme canonique.
///
/// Le backend a changé de convention au fil du temps (anglais 'pending' /
/// 'in_progress' / 'resolved', puis français 'En attente' / 'En cours' /
/// 'Résolu'), donc des signalements existants peuvent avoir l'une ou l'autre
/// forme selon leur date de création/mise à jour. On normalise toujours côté
/// client plutôt que de filtrer côté serveur sur une chaîne exacte.
String normalizeStatus(String status) {
  switch (status.toLowerCase().trim()) {
    case 'en cours':
    case 'in_progress':
      return 'in_progress';
    case 'résolu':
    case 'resolu':
    case 'resolved':
      return 'resolved';
    case 'en attente':
    case 'pending':
    default:
      return 'pending';
  }
}
