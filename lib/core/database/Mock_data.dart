import '../models/goal.dart';
import '../models/task.dart';
import '../models/event.dart';
import '../models/enums.dart';

// ── Goals ─────────────────────────────────────────────────────────────────

final List<Goal> mockGoals = [
  Goal(
    id: 'goal-1',
    name: 'Get Fit',
    type: GoalType.ongoing,
    description: 'Build a consistent workout habit and improve overall health.',
    starttime: DateTime(2025, 1, 1),
    deadline: null,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  ),
  Goal(
    id: 'goal-2',
    name: 'Launch Side Project',
    type: GoalType.completable,
    description: 'Build and ship a Flutter app to the App Store.',
    starttime: DateTime.parse('2026-04-27 14:13:43.101+00'), //DateTime(2026, 2, 1),
    deadline: DateTime.parse('2026-06-27 14:13:43.101+00'), //DateTime(2026, 6, 30),
    createdAt: DateTime(2025, 2, 1),
    updatedAt: DateTime(2025, 3, 10),
  ),
  Goal(
    id: 'goal-3',
    name: 'Read More Books',
    type: GoalType.ongoing,
    description: null,
    starttime: null,
    deadline: DateTime(2025, 6, 15),
    createdAt: DateTime(2025, 1, 15),
    updatedAt: DateTime(2025, 1, 15),
  ),
];

// ── Tasks ─────────────────────────────────────────────────────────────────

final List<Task> mockTasks = [
  Task(
    id: 'task-1',
    name: 'Go for a 5km run',
    goalId: 'goal-1',
    priority: Priority.high,
    starttime: DateTime(2025, 5, 10, 7, 0),
    deadline: DateTime(2025, 5, 10, 8, 0),
    estimatedDurationMinutes: 40,
    effortLevel: EffortLevel.medium,
    status: TaskStatus.done,
    createdAt: DateTime(2025, 5, 1),
    updatedAt: DateTime(2025, 5, 10),
  ),
  Task(
    id: 'task-2',
    name: 'Design app home screen',
    goalId: 'goal-2',
    priority: Priority.high,
    starttime: DateTime(2025, 5, 11, 10, 0),
    deadline: DateTime(2025, 5, 13),
    estimatedDurationMinutes: 120,
    effortLevel: EffortLevel.high,
    status: TaskStatus.inProgress,
    createdAt: DateTime(2025, 5, 2),
    updatedAt: DateTime(2025, 5, 11),
  ),
  Task(
    id: 'task-3',
    name: 'Write unit tests',
    goalId: 'goal-2',
    priority: Priority.medium,
    starttime: null,
    deadline: DateTime(2025, 5, 10),
    estimatedDurationMinutes: 90,
    effortLevel: EffortLevel.medium,
    status: TaskStatus.todo,
    createdAt: DateTime(2025, 5, 3),
    updatedAt: DateTime(2025, 5, 3),
  ),
  Task(
    id: 'task-4',
    name: 'Read 30 pages of current book',
    goalId: 'goal-3',
    priority: Priority.low,
    starttime: null,
    deadline: null,
    estimatedDurationMinutes: 45,
    effortLevel: EffortLevel.low,
    status: TaskStatus.todo,
    createdAt: DateTime(2025, 5, 5),
    updatedAt: DateTime(2025, 5, 5),
  ),
  Task(
    id: 'task-5',
    name: 'Buy groceries',
    goalId: null,
    priority: Priority.medium,
    starttime: null,
    deadline: DateTime(2025, 5, 12),
    estimatedDurationMinutes: 30,
    effortLevel: EffortLevel.low,
    status: TaskStatus.todo,
    createdAt: DateTime(2025, 5, 6),
    updatedAt: DateTime(2025, 5, 6),
  ),
];

// ── Events ────────────────────────────────────────────────────────────────

final List<Event> mockEvents = [
  Event(
    id: 'event-1',
    name: 'Morning Run',
    taskId: 'task-1',
    startTime: DateTime(2025, 5, 10, 7, 0),
    endTime: DateTime(2025, 5, 10, 7, 45),
    isRepeating: true,
    recurrenceRule: 'FREQ=WEEKLY;BYDAY=MO,WE,FR',
    createdAt: DateTime(2025, 5, 1),
    updatedAt: DateTime(2025, 5, 1),
  ),
  Event(
    id: 'event-2',
    name: 'App Design Session',
    taskId: 'task-2',
    startTime: DateTime(2025, 5, 11, 10, 0),
    endTime: DateTime(2025, 5, 11, 12, 0),
    isRepeating: false,
    recurrenceRule: null,
    createdAt: DateTime(2025, 5, 2),
    updatedAt: DateTime(2025, 5, 2),
  ),
  Event(
    id: 'event-3',
    name: 'Evening Reading',
    taskId: 'task-4',
    startTime: DateTime(2025, 5, 10, 21, 0),
    endTime: DateTime(2025, 5, 10, 21, 45),
    isRepeating: true,
    recurrenceRule: 'FREQ=DAILY',
    createdAt: DateTime(2025, 5, 5),
    updatedAt: DateTime(2025, 5, 5),
  ),
  Event(
    id: 'event-4',
    name: 'Grocery Run',
    taskId: 'task-5',
    startTime: DateTime(2025, 5, 12, 18, 0),
    endTime: DateTime(2025, 5, 12, 18, 30),
    isRepeating: false,
    recurrenceRule: null,
    createdAt: DateTime(2025, 5, 6),
    updatedAt: DateTime(2025, 5, 6),
  ),
];