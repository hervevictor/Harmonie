// lib/data/course_catalog.dart
import '../models/course_model.dart';

// ─── Quiz questions (music theory, level assessment) ─────────────────────────

const List<QuizQuestion> kQuizQuestions = [
  QuizQuestion(
    question: 'Combien de notes y a-t-il dans une gamme majeure ?',
    options: ['5', '6', '7', '8'],
    correctIndex: 2,
    explanation: 'Une gamme majeure comporte 7 notes (Do Ré Mi Fa Sol La Si), plus l\'octave.',
  ),
  QuizQuestion(
    question: 'Qu\'est-ce qu\'un accord mineur ?',
    options: [
      'Un accord composé de 2 notes',
      'Un accord avec une tierce mineure (3 demi-tons)',
      'Un accord joué doucement',
      'Un accord sans quinte',
    ],
    correctIndex: 1,
    explanation: 'Un accord mineur est formé d\'une fondamentale, une tierce mineure (3 demi-tons) et une quinte juste.',
  ),
  QuizQuestion(
    question: 'Que signifie BPM en musique ?',
    options: [
      'Basses, Percussions, Mélodies',
      'Battements Par Mesure',
      'Battements Par Minute',
      'Bémol, Pause, Mesure',
    ],
    correctIndex: 2,
    explanation: 'BPM signifie Battements Par Minute — c\'est l\'unité de mesure du tempo.',
  ),
  QuizQuestion(
    question: 'Quelle est la note entre Do et Ré ?',
    options: ['Do#/Réb', 'Mi', 'Si', 'Fa#'],
    correctIndex: 0,
    explanation: 'Entre Do et Ré se trouve Do# (ou Réb), une note à un demi-ton de chaque.',
  ),
  QuizQuestion(
    question: 'Qu\'est-ce qu\'une quinte juste ?',
    options: [
      '5 demi-tons entre deux notes',
      '7 demi-tons entre deux notes',
      '4 tons entre deux notes',
      'Un accord de 5 notes',
    ],
    correctIndex: 1,
    explanation: 'Une quinte juste correspond à 7 demi-tons (ex. Do–Sol). C\'est l\'intervalle le plus stable en harmonie.',
  ),
];

// ─── Static course catalog ────────────────────────────────────────────────────

const List<Course> kCourses = [
  // ── GUITARE ACOUSTIQUE — DÉBUTANT ─────────────────────────────────────────
  Course(
    id: 'guitar_basics',
    instrumentId: 'guitar_acoustic',
    level: CourseLevel.beginner,
    emoji: '🎸',
    title: 'Les bases de la guitare',
    description: 'Posture, accordage et tes premiers accords. Tout commence ici.',
    sections: [
      CourseSection(
        id: 'guitar_basics_1',
        number: 1,
        title: 'Connaître ton instrument',
        content:
            'La guitare acoustique se compose de plusieurs parties essentielles que tout guitariste doit connaître.\n\n'
            'Le corps est la caisse de résonance — c\'est là que le son est amplifié naturellement. '
            'Le manche porte les frettes (les barrettes métalliques) qui délimitent les notes. '
            'La tête contient les mécaniques pour accorder.\n\n'
            'Les 6 cordes de la guitare, de la plus grave à la plus aiguë, sont : Mi (E2), La (A2), Ré (D3), Sol (G3), Si (B3), Mi (E4). '
            'Un bon moyen de les retenir : "Mi La Ré Sol Si Mi" → "Mon Ami Ré Sol Si Montagne".\n\n'
            'Prends le temps d\'explorer ton instrument : touche chaque corde à vide, écoute le son produit.',
        keyPoints: [
          '6 cordes : Mi, La, Ré, Sol, Si, Mi (grave → aigu)',
          'Le manche a des frettes qui délimitent les notes',
          'Le corps amplifie le son naturellement',
          'Les mécaniques (tête) permettent l\'accordage',
        ],
        videoUrl: 'https://www.youtube.com/watch?v=5RYr0ITkGbs',
        videoTitle: 'Les parties de la guitare expliquées',
        exercises: [
          'Joue chaque corde à vide une par une, de la plus grave (Mi bas) à la plus aiguë (Mi haut).',
          'Nomme à voix haute chaque corde en la jouant.',
        ],
        aiExercisePrompt:
            'Je viens d\'apprendre les parties de la guitare et les noms des 6 cordes. '
            'Peux-tu me donner 3 exercices simples pour mémoriser l\'ordre des cordes ?',
      ),
      CourseSection(
        id: 'guitar_basics_2',
        number: 2,
        title: 'Posture et tenue de la guitare',
        content:
            'Une bonne posture est la fondation d\'un jeu sans douleur et sans mauvaises habitudes.\n\n'
            'Assis, pose la guitare sur ta cuisse droite (si tu es droitier). '
            'La tête de la guitare doit pointer légèrement vers le haut — jamais vers le bas. '
            'Garde le dos droit, les épaules décontractées.\n\n'
            'Main gauche (main de frettes) : le pouce se pose derrière le manche, à mi-hauteur. '
            'Les doigts arrivent sur les cordes par en haut, presque perpendiculairement aux frettes. '
            'Ne laisse pas le pouce dépasser au-dessus du manche.\n\n'
            'Main droite (main de jeu) : tu peux utiliser un médiator (plectre) ou tes doigts. '
            'Pour commencer, le médiator tenu entre pouce et index est recommandé. '
            'Garde le poignet détendu — la rigidité fatigue rapidement.',
        keyPoints: [
          'Guitare sur la cuisse droite, tête légèrement vers le haut',
          'Dos droit, épaules décontractées',
          'Pouce gauche derrière le manche, pas au-dessus',
          'Médiator tenu entre pouce et index, poignet souple',
        ],
        exercises: [
          'Prends ta guitare et adopte la position correcte pendant 5 minutes sans jouer — juste pour sentir le confort.',
          'Essaie de placer ton index gauche sur la 1ère frette de la corde de Sol et joue la note.',
        ],
        aiExercisePrompt:
            'Je travaille ma posture à la guitare. Quels sont les erreurs de posture les plus courantes chez les débutants, et comment les corriger ?',
      ),
      CourseSection(
        id: 'guitar_basics_3',
        number: 3,
        title: 'Accorder ta guitare',
        content:
            'Un instrument désaccordé donne une musique qui sonne faux, même si tu joues les bonnes notes. '
            'Apprendre à accorder ta guitare est donc une priorité absolue.\n\n'
            'L\'accordage standard est (grave → aigu) : Mi – La – Ré – Sol – Si – Mi.\n\n'
            'Méthodes d\'accordage :\n'
            '1. Accordeur clip (chromatic tuner) : clipse sur la tête, joue chaque corde et suis l\'affichage. C\'est la méthode la plus fiable pour débuter.\n'
            '2. Application mobile : beaucoup d\'apps gratuites fonctionnent très bien.\n'
            '3. Par oreille (à venir) : plus difficile, mais développe l\'oreille musicale.\n\n'
            'Pour accorder : tourne les mécaniques doucement. Monter = serrer la corde = son plus aigu. '
            'Descendre = détendre = son plus grave. Approche toujours la note par le bas pour éviter de casser une corde.',
        keyPoints: [
          'Accordage standard : Mi-La-Ré-Sol-Si-Mi',
          'Utilise un accordeur chromique ou une app pour débuter',
          'Approche toujours la note par le bas',
          'Accorde avant chaque session de jeu',
        ],
        videoUrl: 'https://www.youtube.com/watch?v=P9Plg3fwGSY',
        videoTitle: 'Comment accorder sa guitare — tutoriel débutant',
        exercises: [
          'Accorde ta guitare avec un accordeur ou une app. Répète 3 fois (désaccorde légèrement, puis ré-accorde).',
          'Essaie d\'identifier si une corde sonne "trop haut" ou "trop bas" par rapport à l\'accordeur.',
        ],
        aiExercisePrompt:
            'Je viens d\'apprendre à accorder ma guitare en accordage standard. '
            'Peux-tu m\'expliquer d\'autres types d\'accordages (Drop D, Open G) et quand on les utilise ?',
      ),
      CourseSection(
        id: 'guitar_basics_4',
        number: 4,
        title: 'Tes 3 premiers accords : La, Ré, Mi',
        content:
            'Avec seulement 3 accords, tu peux jouer des centaines de chansons. '
            'Ces 3 accords forment une progression très courante dans la musique populaire.\n\n'
            'Accord de La majeur (A) :\n'
            'Corde 5 à vide (La), corde 4 frette 2 (index), corde 3 frette 2 (majeur), corde 2 frette 2 (annulaire). '
            'Ne joue pas les cordes 6 et 1.\n\n'
            'Accord de Ré majeur (D) :\n'
            'Corde 4 à vide (Ré), corde 3 frette 2 (index), corde 1 frette 2 (majeur), corde 2 frette 3 (annulaire). '
            'Ne joue pas les cordes 5 et 6.\n\n'
            'Accord de Mi majeur (E) :\n'
            'Corde 6 à vide, corde 5 frette 2 (majeur), corde 4 frette 2 (annulaire), corde 3 à vide, corde 2 à vide, corde 1 à vide.\n\n'
            'Astuce : Place l\'accord, gratte toutes les cordes lentement, écoute chaque note. '
            'Ajuste les doigts qui sonnent "étouffés". La régularité prime sur la vitesse.',
        keyPoints: [
          'La (A) : index-majeur-annulaire sur frette 2 (cordes 4-3-2)',
          'Ré (D) : 3 doigts sur cordes 3-2-1, frettes 2-3-2',
          'Mi (E) : 2 doigts sur cordes 5-4, frette 2',
          'Enchaine lentement entre les accords — la fluidité vient avec la pratique',
        ],
        exercises: [
          'Joue chaque accord 10 fois de suite en te concentrant sur la clarté du son.',
          'Alterne La → Ré → Mi → La pendant 5 minutes à rythme lent (1 accord toutes les 4 secondes).',
          'Cherche une chanson qui utilise ces 3 accords et essaie de la jouer.',
        ],
        aiExercisePrompt:
            'Je viens d\'apprendre les accords La, Ré et Mi à la guitare. '
            'Donne-moi une liste de 5 chansons simples qui utilisent seulement ces 3 accords, et comment les enchaîner.',
      ),
    ],
  ),

  Course(
    id: 'guitar_tablature',
    instrumentId: 'guitar_acoustic',
    level: CourseLevel.beginner,
    emoji: '📄',
    title: 'Lire une tablature',
    description: 'Apprends à déchiffrer les tabs — la notation simplifiée de la guitare.',
    sections: [
      CourseSection(
        id: 'guitar_tab_1',
        number: 1,
        title: 'Qu\'est-ce qu\'une tablature ?',
        content:
            'La tablature (ou "tab") est un système de notation spécifique aux instruments à cordes. '
            'Contrairement au solfège classique, elle ne représente pas les hauteurs de notes sur une portée, '
            'mais directement les positions sur l\'instrument.\n\n'
            'Une tab de guitare se présente comme 6 lignes horizontales, représentant les 6 cordes. '
            'La ligne du bas = corde Mi grave, la ligne du haut = corde Mi aigu.\n\n'
            'Les chiffres sur les lignes indiquent quelle frette presser. '
            '0 = corde à vide, 1 = 1ère frette, 5 = 5ème frette, etc.\n\n'
            'Exemple d\'un riff simple :\n'
            'e|---0---2---3---|\n'
            'B|---1---3---3---|\n'
            'G|---0---2---2---|\n'
            'D|---2---0---0---|\n'
            'A|---3-----------|\n'
            'E|---------------|\n\n'
            'Les notes alignées verticalement se jouent en même temps (accord). '
            'Les notes en séquence horizontale se jouent l\'une après l\'autre.',
        keyPoints: [
          '6 lignes = 6 cordes (bas = Mi grave, haut = Mi aigu)',
          'Chiffres = numéro de frette à presser',
          '0 = corde à vide (aucun doigt)',
          'Notes verticales = simultanées, horizontales = séquentielles',
        ],
        videoUrl: 'https://www.youtube.com/watch?v=MFUFv1gNHu4',
        videoTitle: 'Lire une tablature de guitare en 5 minutes',
        exercises: [
          'Dessine une tablature simple sur papier et joue les 3 premières notes.',
          'Cherche la tab d\'une chanson que tu connais et identifie les 0 (cordes à vide).',
        ],
        aiExercisePrompt:
            'Je viens d\'apprendre à lire les tablatures de guitare. '
            'Peux-tu me donner 3 riffs simples en tablature pour débutant avec leur explication ?',
      ),
      CourseSection(
        id: 'guitar_tab_2',
        number: 2,
        title: 'Techniques de base dans les tabs',
        content:
            'Les tablatures utilisent des symboles spéciaux pour noter différentes techniques de jeu.\n\n'
            'h = hammer-on : tu places un doigt sur une frette sans gratter la corde (ex: 5h7 = joue frette 5, puis "tape" frette 7).\n\n'
            'p = pull-off : l\'inverse du hammer-on. Tu retires ton doigt en "tirant" légèrement la corde (ex: 7p5).\n\n'
            'b = bend : tu pousses la corde latéralement pour monter d\'un demi-ton ou un ton (ex: 7b = bend sur frette 7).\n\n'
            '/ = slide up : tu fais glisser ton doigt vers le haut (ex: 5/7).\n\n'
            'x = note étouffée : tu poses le doigt sans appuyer — produit un son "click".\n\n'
            'Ces techniques s\'apprennent progressivement. Pour débuter, concentre-toi sur les notes normales et les cordes à vide.',
        keyPoints: [
          'h = hammer-on (tape sans gratter)',
          'p = pull-off (tire le doigt)',
          'b = bend (pousse la corde latéralement)',
          '/ = slide (glisse le doigt)',
          'x = note étouffée',
        ],
        exercises: [
          'Pratique un simple hammer-on : joue la corde de Sol à vide (0), puis tape immédiatement la frette 2.',
          'Essaie un slide : place ton index sur frette 5 de la corde Mi aigu, joue et glisse jusqu\'à frette 7.',
        ],
        aiExercisePrompt:
            'Je veux m\'entraîner au hammer-on et pull-off à la guitare. '
            'Donne-moi une progression d\'exercices du plus simple au plus complexe.',
      ),
    ],
  ),

  // ── GUITARE ACOUSTIQUE — JUNIOR ───────────────────────────────────────────
  Course(
    id: 'guitar_arpeggios',
    instrumentId: 'guitar_acoustic',
    level: CourseLevel.junior,
    emoji: '🎵',
    title: 'Arpèges et rythme',
    description: 'Dépasse le simple grattage — joue les accords corde par corde avec élégance.',
    sections: [
      CourseSection(
        id: 'guitar_arp_1',
        number: 1,
        title: 'Qu\'est-ce qu\'un arpège ?',
        content:
            'Un arpège, c\'est un accord dont les notes sont jouées une par une plutôt que simultanément. '
            'C\'est une technique fondamentale qui donne une texture plus douce et plus mélodique à ton jeu.\n\n'
            'Le pattern le plus classique pour débutant : "Pouce – Index – Majeur – Annulaire – Majeur – Index"\n\n'
            'Pour l\'accord de Do majeur (x32010) :\n'
            'Pouce joue corde 5 (La)\n'
            'Index joue corde 3 (Sol)\n'
            'Majeur joue corde 2 (Si)\n'
            'Annulaire joue corde 1 (Mi)\n\n'
            'La clé est de garder l\'accord plaqué tout le temps pendant que tu joues l\'arpège. '
            'Commence très lentement — 60 BPM — puis accélère progressivement.',
        keyPoints: [
          'Arpège = notes de l\'accord jouées une par une',
          'Pattern classique : pouce–index–majeur–annulaire',
          'Garde l\'accord plaqué pendant tout l\'arpège',
          'Commence à 60 BPM, augmente progressivement',
        ],
        videoUrl: 'https://www.youtube.com/watch?v=bbOFMKFaB5s',
        videoTitle: 'Apprendre les arpèges pour débutant',
        exercises: [
          'Joue l\'arpège Do – Fa – Sol – Do (4 mesures chacun) à 60 BPM.',
          'Écoute "Tears in Heaven" d\'Eric Clapton et identifie l\'arpège dans l\'intro.',
        ],
        aiExercisePrompt:
            'Je débute les arpèges à la guitare acoustique. '
            'Propose-moi 4 patterns d\'arpèges progressifs du plus simple au plus complexe, avec la notation des doigts.',
      ),
      CourseSection(
        id: 'guitar_arp_2',
        number: 2,
        title: 'Le rythme et le strumming',
        content:
            'Le rythme est l\'âme de la musique. Un accord parfaitement plaqué sur un mauvais rythme sonne mal. '
            'Un accord moyen sur un rythme solide sonne bien.\n\n'
            'Strumming (grattage) : les 2 directions :\n'
            '↓ = downstroke : gratte du haut vers le bas (naturel)\n'
            '↑ = upstroke : gratte du bas vers le haut (main "remonte")\n\n'
            'Pattern de base (4/4) : ↓ ↓ ↑ ↓ ↑\n'
            'Compte : 1 – 2 – "et" – 3 – "et"\n\n'
            'Astuces :\n'
            '- Le mouvement vient du poignet, pas du coude\n'
            '- L\'upstroke effleure seulement les cordes aiguës (2-3 cordes)\n'
            '- Garde le bras en mouvement même quand tu "rates" certains downstrokes\n\n'
            'Exercice de rythme fondamental : tape le rythme sur ta cuisse avant de le jouer à la guitare.',
        keyPoints: [
          '↓ downstroke, ↑ upstroke — apprends les 2 directions',
          'Pattern de base : ↓ ↓ ↑ ↓ ↑ (compte 1-2-et-3-et)',
          'Mouvement du poignet, pas du coude',
          'Utilise un métronome — commence lentement',
        ],
        exercises: [
          'Joue l\'accord de La avec le pattern ↓ ↓ ↑ ↓ ↑ à 70 BPM pendant 2 minutes sans t\'arrêter.',
          'Enchaîne La → Ré → Mi avec ce pattern à 60 BPM.',
        ],
        aiExercisePrompt:
            'Je travaille le strumming à la guitare. Donne-moi 5 patterns de strumming progressifs pour la musique pop/rock, du plus simple au plus complexe.',
      ),
    ],
  ),

  Course(
    id: 'guitar_pentatonic',
    instrumentId: 'guitar_acoustic',
    level: CourseLevel.junior,
    emoji: '🎸',
    title: 'La gamme pentatonique',
    description: 'La gamme des guitaristes — base de tous les solos.',
    sections: [
      CourseSection(
        id: 'guitar_penta_1',
        number: 1,
        title: 'La gamme pentatonique mineure',
        content:
            'La gamme pentatonique mineure est la gamme la plus utilisée pour les solos de guitare. '
            '"Penta" = 5 notes. Elle est simple, sonne bien sur presque tout, et est la porte d\'entrée vers l\'improvisation.\n\n'
            'Position 1 de la pentatonique mineure de La (A minor pentatonic) :\n'
            'Corde 6 : frettes 5 et 8\n'
            'Corde 5 : frettes 5 et 7\n'
            'Corde 4 : frettes 5 et 7\n'
            'Corde 3 : frettes 5 et 7\n'
            'Corde 2 : frettes 5 et 8\n'
            'Corde 1 : frettes 5 et 8\n\n'
            'Joue cette gamme en montant (corde 6 → 1) puis en descendant (corde 1 → 6). '
            'Note que cette position commence sur la frette 5 — c\'est la "tonique" La.',
        keyPoints: [
          '5 notes : La Do Ré Mi Sol (en La mineur)',
          'Position 1 commence frette 5 corde 6',
          'Joue la montée et la descente lentement',
          'Cette gamme est la base de tous les solos blues, rock, pop',
        ],
        videoUrl: 'https://www.youtube.com/watch?v=rPdn7c8_bKA',
        videoTitle: 'Gamme pentatonique mineure — position 1',
        exercises: [
          'Joue la position 1 en montée et descente à 60 BPM avec un métronome pendant 10 minutes.',
          'Improvise librement sur un backing track en La mineur (cherche "Am backing track" sur YouTube).',
        ],
        aiExercisePrompt:
            'Je viens d\'apprendre la gamme pentatonique mineure de La en position 1. '
            'Comment l\'utiliser pour improviser ? Donne-moi des exercices de phrasé pour créer de vraies lignes mélodiques.',
      ),
    ],
  ),

  // ── GUITARE ACOUSTIQUE — INTERMÉDIAIRE ───────────────────────────────────
  Course(
    id: 'guitar_barre',
    instrumentId: 'guitar_acoustic',
    level: CourseLevel.intermediate,
    emoji: '💪',
    title: 'Accords de barré et transpositions',
    description: 'Maîtrise les accords de barré et joue dans toutes les tonalités.',
    sections: [
      CourseSection(
        id: 'guitar_barre_1',
        number: 1,
        title: 'Le barré : technique et pièges',
        content:
            'L\'accord de barré est l\'obstacle classique de tout guitariste débutant-intermédiaire. '
            'L\'index presse toutes les cordes en même temps, sur une frette entière.\n\n'
            'Barré en position Mi (forme E) sur frette 5 = La majeur :\n'
            'Index barre la frette 5 sur toutes les cordes\n'
            'Majeur : corde 5, frette 6\n'
            'Annulaire : corde 4, frette 7\n'
            'Auriculaire : corde 3, frette 7\n\n'
            'Erreurs communes :\n'
            '- Index trop penché : tourne-le légèrement vers le haut du manche\n'
            '- Index trop loin de la frette : colle l\'index juste derrière la frette\n'
            '- Pouce trop haut : descends le pouce derrière le manche\n\n'
            'C\'est une question de force et de placement. Quelques semaines de pratique quotidienne suffisent.',
        keyPoints: [
          'L\'index barre toute la frette — technique de placement cruciale',
          'Forme E sur frette 5 = La majeur (système transposable)',
          'Index légèrement tourné, collé juste derrière la frette',
          'Pouce bas derrière le manche pour plus de force',
        ],
        exercises: [
          'Place un barré sur frette 5, joue corde par corde pour vérifier que chaque note sonne.',
          'Alterne entre Mi majeur (position ouverte) et La majeur barré frette 5.',
        ],
        aiExercisePrompt:
            'Je travaille les accords de barré à la guitare. Mes cordes sonnent étouffées. '
            'Quelles sont les techniques précises pour améliorer la clarté du barré ? Donne-moi un plan de travail de 2 semaines.',
      ),
    ],
  ),

  // ── GUITARE ACOUSTIQUE — AVANCÉ ───────────────────────────────────────────
  Course(
    id: 'guitar_harmony',
    instrumentId: 'guitar_acoustic',
    level: CourseLevel.advanced,
    emoji: '🎓',
    title: 'Harmonie et improvisation avancée',
    description: 'Les modes, les substitutions d\'accords et l\'improvisation modale.',
    sections: [
      CourseSection(
        id: 'guitar_harm_1',
        number: 1,
        title: 'Introduction aux modes de la gamme majeure',
        content:
            'La gamme majeure génère 7 modes selon la note de départ. '
            'Chaque mode a une couleur sonore distincte.\n\n'
            'Les 7 modes de Do majeur :\n'
            '1. Ionien (Do) — joyeux, stable — la gamme majeure classique\n'
            '2. Dorien (Ré) — mineur jazzy — utilisé dans "So What" de Miles Davis\n'
            '3. Phrygien (Mi) — espagnol, sombre\n'
            '4. Lydien (Fa) — flottant, mystérieux — John Williams adore ce mode\n'
            '5. Mixolydien (Sol) — blues-rock — "Sweet Home Chicago"\n'
            '6. Éolien (La) — mineur naturel — le plus commun en rock\n'
            '7. Locrien (Si) — instable, rarement utilisé seul\n\n'
            'La clé : un mode n\'est pas une gamme différente, c\'est une façon différente d\'entendre la même gamme.',
        keyPoints: [
          '7 modes dérivés de la gamme majeure',
          'Dorien = mineur jazzy, Mixolydien = blues-rock, Éolien = mineur naturel',
          'Un mode change la "couleur" harmonique sans changer les notes',
          'Application : choisir le bon mode selon la progression d\'accords',
        ],
        videoUrl: 'https://www.youtube.com/watch?v=gBHGFG6ZVSA',
        videoTitle: 'Les 7 modes expliqués en 10 minutes',
        exercises: [
          'Joue chaque mode de Do majeur en commençant sur la bonne note. Écoute la différence de couleur.',
          'Improvise en mode Dorien sur un backing track en Ré mineur.',
        ],
        aiExercisePrompt:
            'Je viens d\'apprendre les 7 modes de la gamme majeure à la guitare. '
            'Donne-moi une progression d\'accords pour chaque mode avec un exercice d\'improvisation adapté.',
      ),
    ],
  ),

  // ══ PIANO ══════════════════════════════════════════════════════════════════

  // ── PIANO — DÉBUTANT ─────────────────────────────────────────────────────
  Course(
    id: 'piano_basics',
    instrumentId: 'piano',
    level: CourseLevel.beginner,
    emoji: '🎹',
    title: 'Découvrir le piano',
    description: 'Les touches, la position des mains et ta première mélodie.',
    sections: [
      CourseSection(
        id: 'piano_basics_1',
        number: 1,
        title: 'Le clavier et les notes',
        content:
            'Le piano standard possède 88 touches — 52 blanches et 36 noires. '
            'Les touches blanches correspondent aux notes naturelles : Do, Ré, Mi, Fa, Sol, La, Si. '
            'Les touches noires sont les dièses (#) et bémols (b).\n\n'
            'Comment s\'orienter sur le clavier :\n'
            'Les touches noires sont groupées en blocs de 2 et de 3. '
            'Le Do est toujours la touche blanche juste à gauche d\'un groupe de 2 touches noires. '
            'Le Do central (Do 4) est au milieu du piano, juste à gauche des 2 touches noires du milieu.\n\n'
            'Octaves : les 7 notes se répètent sur toute la longueur du clavier. '
            'Do3, Do4, Do5 sont tous des Do — le chiffre indique l\'octave (hauteur).\n\n'
            'Commence par trouver et jouer tous les Do du clavier, puis tous les Sol.',
        keyPoints: [
          'Touches blanches : Do Ré Mi Fa Sol La Si',
          'Do = juste à gauche des 2 touches noires groupées',
          'Touches noires = dièses/bémols',
          'Les 7 notes se répètent sur toutes les octaves',
        ],
        videoUrl: 'https://www.youtube.com/watch?v=HBX5e7jjQTk',
        videoTitle: 'Apprendre les notes du piano rapidement',
        exercises: [
          'Trouve et joue tous les Do du clavier (il y en a 8 sur un piano standard).',
          'Joue la gamme de Do majeur en montée : Do Ré Mi Fa Sol La Si Do.',
        ],
        aiExercisePrompt:
            'Je viens d\'apprendre les notes du piano. Donne-moi 3 exercices ludiques pour mémoriser la position des notes sur le clavier sans regarder.',
      ),
      CourseSection(
        id: 'piano_basics_2',
        number: 2,
        title: 'Position des mains et doigtés',
        content:
            'La position correcte des mains au piano prévient les blessures et facilite la technique.\n\n'
            'Position naturelle : imagine que tu tiens une orange dans chaque main. '
            'Les doigts sont légèrement courbés, la paume légèrement arrondie. '
            'Les doigts tombent sur les touches de manière détendue.\n\n'
            'Numérotation des doigts :\n'
            'Pouce = 1, Index = 2, Majeur = 3, Annulaire = 4, Auriculaire = 5\n\n'
            'Doigté de la gamme de Do majeur (main droite) :\n'
            'Do(1) Ré(2) Mi(3) Fa(1) Sol(2) La(3) Si(4) Do(5)\n'
            'Note le passage du pouce sous le majeur entre Mi et Fa — c\'est le "passage de pouce".\n\n'
            'Main gauche (gamme de Do majeur, descente) :\n'
            'Do(5) Si(4) La(3) Sol(2) Fa(1) Mi(3) Ré(2) Do(1)',
        keyPoints: [
          'Mains courbées comme autour d\'une orange — jamais plates',
          'Doigts : Pouce=1, Index=2, Majeur=3, Annulaire=4, Auriculaire=5',
          'Le passage de pouce (3→1) est la base de toutes les gammes',
          'Poignets souples, épaules décontractées',
        ],
        exercises: [
          'Pose les 5 doigts de la main droite sur Do Ré Mi Fa Sol. Joue chaque note une par une (1-2-3-4-5 puis 5-4-3-2-1).',
          'Pratique le passage de pouce : joue Mi(3) puis place le pouce sur Fa pendant que le majeur joue Mi.',
        ],
        aiExercisePrompt:
            'Je travaille le doigté et la position des mains au piano. '
            'Quels exercices techniques (Hanon, Czerny ?) me recommandes-tu pour un débutant, et comment les pratiquer efficacement ?',
      ),
      CourseSection(
        id: 'piano_basics_3',
        number: 3,
        title: 'Ta première mélodie : "Frère Jacques"',
        content:
            'Il est temps de jouer ta première mélodie complète ! '
            '"Frère Jacques" est parfaite pour débuter — simple, connue, et elle utilise les gammes vues précédemment.\n\n'
            'Notes de la mélodie (main droite, Do central) :\n'
            'Frère Ja-ques : Do Ré Mi Do | Do Ré Mi Do\n'
            'Dor-mez vous : Mi Fa Sol | Mi Fa Sol\n'
            'Son-nez les ma-ti-nes : Sol La Sol Fa Mi Do | Sol La Sol Fa Mi Do\n'
            'Din din don : Sol Fa Mi Do Sol | Sol Fa Mi Do Sol | Do — |\n\n'
            'Doigtés : utilise 1=Do, 2=Ré, 3=Mi, 4=Fa, 5=Sol. '
            'Pour La, remonte le pouce (passage).\n\n'
            'Conseils :\n'
            '- Apprends phrase par phrase, pas d\'un coup\n'
            '- Joue très lentement au début\n'
            '- Regarde tes doigts au début, puis essaie sans regarder',
        keyPoints: [
          'Apprends phrase musicale par phrase',
          'Lenteur = précision = fondation de la rapidité future',
          'Doigtés : 1=Do 2=Ré 3=Mi 4=Fa 5=Sol',
          'Objectif final : jouer sans regarder le clavier',
        ],
        exercises: [
          'Joue "Frère Jacques" main droite seulement, très lentement. Répète 5 fois.',
          'Une fois fluide, essaie de chanter les paroles en jouant.',
        ],
        aiExercisePrompt:
            'J\'arrive à jouer "Frère Jacques" au piano avec la main droite. '
            'Propose-moi 3 autres mélodies simples pour débutant à apprendre ensuite, avec les notes écrites.',
      ),
    ],
  ),

  // ── PIANO — JUNIOR ───────────────────────────────────────────────────────
  Course(
    id: 'piano_chords',
    instrumentId: 'piano',
    level: CourseLevel.junior,
    emoji: '🎵',
    title: 'Accords au piano : les deux mains',
    description: 'Joue la mélodie d\'une main et les accords de l\'autre.',
    sections: [
      CourseSection(
        id: 'piano_chords_1',
        number: 1,
        title: 'Les accords de base (triade)',
        content:
            'Un accord = au moins 3 notes jouées simultanément. '
            'Les triades sont les accords les plus simples : fondamentale + tierce + quinte.\n\n'
            'Accord de Do majeur : Do – Mi – Sol (touches blanches !)\n'
            'Accord de Ré mineur : Ré – Fa – La\n'
            'Accord de Mi mineur : Mi – Sol – Si\n'
            'Accord de Fa majeur : Fa – La – Do\n'
            'Accord de Sol majeur : Sol – Si – Ré\n'
            'Accord de La mineur : La – Do – Mi\n\n'
            'Formule magique :\n'
            'Majeur = fondamentale + 4 demi-tons + 3 demi-tons\n'
            'Mineur = fondamentale + 3 demi-tons + 4 demi-tons\n\n'
            'Renversements : un accord peut être joué en commençant par n\'importe quelle de ses notes. '
            'Do-Mi-Sol = Sol-Do-Mi = Mi-Sol-Do — même accord, couleur différente.',
        keyPoints: [
          'Triade = fondamentale + tierce + quinte (3 notes)',
          'Majeur : 4 + 3 demi-tons | Mineur : 3 + 4 demi-tons',
          'Les renversements permettent des enchaînements plus fluides',
          'Accords de Do, Fa, Sol = progression I-IV-V en Do',
        ],
        exercises: [
          'Joue chaque accord de la gamme de Do (Do, Ré mineur, Mi mineur, Fa, Sol, La mineur) un par un.',
          'Enchaîne Do – Fa – Sol – Do à la main gauche en rythme régulier.',
        ],
        aiExercisePrompt:
            'J\'apprends les accords triades au piano. Explique-moi les renversements d\'accords et donne-moi des exercices pour les pratiquer en Do majeur.',
      ),
      CourseSection(
        id: 'piano_chords_2',
        number: 2,
        title: 'Coordination des deux mains',
        content:
            'La coordination main droite / main gauche est le défi principal du piano. '
            'Chaque main fait quelque chose de différent en même temps.\n\n'
            'Stratégie pour apprendre une pièce à 2 mains :\n'
            '1. Apprends la main droite seule (mélodie) jusqu\'à la maîtrise\n'
            '2. Apprends la main gauche seule (accords/basse) jusqu\'à la maîtrise\n'
            '3. Combine très lentement — 50% de la vitesse finale\n'
            '4. Augmente graduellement la vitesse\n\n'
            'Pattern de base main gauche : "Boom-chick"\n'
            'Temps 1 : joue la fondamentale de l\'accord (basse)\n'
            'Temps 2 : joue l\'accord complet\n'
            'Temps 1 : fondamentale | Temps 2 : accord | Temps 3 : fondamentale | Temps 4 : accord\n\n'
            'Exercice phare : main gauche fait Do-sol (basse + accord), main droite joue la mélodie de "Frère Jacques".',
        keyPoints: [
          'Apprends chaque main séparément avant de combiner',
          'Commence à 50% de la vitesse cible pour les 2 mains ensemble',
          'Pattern "Boom-chick" : basse seule puis accord',
          'La coordination vient avec la répétition — sois patient',
        ],
        exercises: [
          'Main gauche : joue Do (basse) + Do-Mi-Sol (accord) en alternance, 4 temps chacun.',
          'Combine avec la main droite jouant "Frère Jacques" — très lentement !',
        ],
        aiExercisePrompt:
            'J\'ai du mal à coordonner mes deux mains au piano. '
            'Donne-moi une routine de 15 minutes quotidienne pour améliorer la coordination main gauche / main droite.',
      ),
    ],
  ),

  // ── PIANO — INTERMÉDIAIRE ─────────────────────────────────────────────────
  Course(
    id: 'piano_scales',
    instrumentId: 'piano',
    level: CourseLevel.intermediate,
    emoji: '🎼',
    title: 'Gammes majeures et mineures',
    description: 'Maîtrise les 12 gammes majeures et leurs relatives mineures.',
    sections: [
      CourseSection(
        id: 'piano_scales_1',
        number: 1,
        title: 'Le cycle des quintes',
        content:
            'Le cycle des quintes est la carte de navigation de la théorie musicale. '
            'Il organise les 12 tonalités en cercle selon leurs relations harmoniques.\n\n'
            'Dans le sens des aiguilles : Do – Sol – Ré – La – Mi – Si – Fa# – Do# – Sol# – Ré# – La# – Fa – Do\n'
            'Chaque pas vers la droite = +1 dièse à la clé\n'
            'Chaque pas vers la gauche = +1 bémol à la clé\n\n'
            'Do : 0 altération\n'
            'Sol : 1 dièse (Fa#)\n'
            'Ré : 2 dièses (Fa#, Do#)\n'
            'La : 3 dièses\n'
            '...\n\n'
            'Utilité : le cycle des quintes te dit instantanément quelles notes sont altérées dans une tonalité, '
            'quels accords appartiennent à cette tonalité, et comment moduler.',
        keyPoints: [
          'Do: 0 altération, Sol: 1#, Ré: 2#, La: 3#...',
          'Chaque cran à droite = +1 dièse à la clé',
          'Chaque cran à gauche = +1 bémol à la clé',
          'Outil fondamental pour comprendre l\'harmonie tonale',
        ],
        videoUrl: 'https://www.youtube.com/watch?v=d1aJ6HixSe4',
        videoTitle: 'Le cycle des quintes expliqué simplement',
        exercises: [
          'Joue la gamme de Sol majeur (avec Fa#) à 2 mains, en montée et descente.',
          'Joue la gamme de Fa majeur (avec Sib) à 2 mains.',
        ],
        aiExercisePrompt:
            'J\'apprends le cycle des quintes au piano. Donne-moi un plan pour apprendre les 12 gammes majeures en 4 semaines, avec les doigtés spécifiques pour les gammes avec altérations.',
      ),
    ],
  ),

  // ── PIANO — AVANCÉ ────────────────────────────────────────────────────────
  Course(
    id: 'piano_jazz',
    instrumentId: 'piano',
    level: CourseLevel.advanced,
    emoji: '🎷',
    title: 'Harmonie jazz et voicings',
    description: 'Extensions d\'accords, voicings et les bases de l\'improvisation jazz.',
    sections: [
      CourseSection(
        id: 'piano_jazz_1',
        number: 1,
        title: 'Accords de 7ème et extensions',
        content:
            'En jazz, les triades sont enrichies d\'extensions : 7ème, 9ème, 11ème, 13ème.\n\n'
            'Accord de 7ème de dominante (C7) : Do – Mi – Sol – Sib\n'
            '→ Tension qui veut se résoudre vers Fa majeur\n\n'
            'Accord majeur 7 (Cmaj7) : Do – Mi – Sol – Si\n'
            '→ Doux, rêveur — très utilisé en bossa nova\n\n'
            'Accord mineur 7 (Cm7) : Do – Mib – Sol – Sib\n'
            '→ Cool, mélancolique — base du ii-V-I\n\n'
            'La progression ii-V-I en Do :\n'
            'Dm7 – G7 – Cmaj7\n'
            'C\'est la progression fondamentale du jazz — elle est partout.\n\n'
            'Voicings : en jazz, on n\'empile pas toujours les notes dans l\'ordre. '
            'On omit souvent la fondamentale et la quinte pour garder seulement la 3ème, 7ème et extensions '
            '— c\'est plus coloré et laisse de la place au bassiste.',
        keyPoints: [
          'Cmaj7 = Do Mi Sol Si | Cm7 = Do Mib Sol Sib | C7 = Do Mi Sol Sib',
          'ii-V-I = Dm7 – G7 – Cmaj7 (progression jazz fondamentale)',
          'Omets la fondamentale et quinte en voicing jazz',
          'Les extensions (9, 11, 13) colorent l\'accord',
        ],
        videoUrl: 'https://www.youtube.com/watch?v=6yy2Hp3bhMM',
        videoTitle: 'Les accords de 7ème au piano — guide complet',
        exercises: [
          'Joue la progression ii-V-I en Do, Sol, Fa et Ré.',
          'Joue les accords en voicing : main gauche = 3ème, main droite = 7ème + extension.',
        ],
        aiExercisePrompt:
            'Je maîtrise les accords de 7ème jazz et la progression ii-V-I. '
            'Comment commencer à improviser sur cette progression ? Quelle gamme utiliser, comment penser le phrasé jazz ?',
      ),
    ],
  ),
];
