import SwiftUI

struct TaskShelfSection: View {
    enum Mode {
        case manage
        case selection(selectedTaskIDs: Binding<Set<FocusTask.ID>>, customTaskTitle: Binding<String>)
    }

    @ObservedObject var model: AppModel
    let title: String
    let mode: Mode

    @State private var isAddingTask = false
    @State private var newTaskTitle = ""
    @State private var editingTaskID: FocusTask.ID?
    @State private var editingTaskTitle = ""
    @FocusState private var taskEditorFocused: Bool

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(title).font(.system(size: 14, weight: .semibold))
                Spacer()
                if case .manage = mode {
                    Text("\(model.completedTaskCount) / \(model.tasks.count)")
                        .font(.system(size: 11))
                        .foregroundStyle(Palette.muted)
                }
                Button(action: beginAddingTask) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .semibold))
                        .adaptiveHitTarget(minWidth: 28, minHeight: 28)
                }
                .buttonStyle(ZaichangPlainButtonStyle())
                .disabled(!model.canAddTask)
                .opacity(model.canAddTask ? 1 : 0.4)
                .help(model.canAddTask ? "新增桌上事项" : "桌上最多放 \(AppModel.maximumTaskCount) 件事")
                .accessibilityLabel("新增桌上事项")
            }
            .padding(.bottom, 7)

            if isAddingTask {
                taskEditor(
                    title: $newTaskTitle,
                    placeholder: "要做的一件事",
                    confirm: commitNewTask,
                    cancel: cancelAddingTask
                )
            }

            if displayedTasks.isEmpty && !isAddingTask {
                Text(emptyStateText)
                    .font(.system(size: 10))
                    .foregroundStyle(Palette.muted)
                    .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
            }

            ForEach(displayedTasks) { task in
                switch mode {
                case .manage:
                    if editingTaskID == task.id {
                        taskEditor(
                            title: $editingTaskTitle,
                            placeholder: "事项名称",
                            confirm: commitTaskRename,
                            cancel: cancelTaskRename
                        )
                    } else {
                        manageRow(task)
                    }
                case let .selection(selectedTaskIDs, _):
                    selectionRow(task, isSelected: selectedTaskIDs.wrappedValue.contains(task.id), selectedTaskIDs: selectedTaskIDs)
                }
            }

            if case let .selection(_, customTaskTitle) = mode {
                TextField("Others（可选）", text: customTaskTitle)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 11))
                    .accessibilityLabel("Others")
            }
        }
    }

    private var displayedTasks: [FocusTask] {
        switch mode {
        case .manage:
            return model.orderedTasks
        case .selection:
            return model.incompleteTasks
        }
    }

    private var emptyStateText: String {
        switch mode {
        case .manage:
            return "桌上还没有要做的事"
        case .selection:
            return "今天还没有待选 Todo"
        }
    }

    private func manageRow(_ task: FocusTask) -> some View {
        HStack(spacing: 8) {
            Button { model.toggleTask(task.id) } label: {
                Image(systemName: task.isCompleted ? "checkmark.square.fill" : "square")
                    .foregroundStyle(task.isCompleted ? Palette.moss : Palette.muted)
                    .adaptiveHitTarget(minWidth: 24, minHeight: 30)
            }
            .buttonStyle(ZaichangPlainButtonStyle())
            .accessibilityLabel(task.isCompleted ? "标记为未完成" : "标记为已完成")

            Text(task.title)
                .font(.system(size: 13))
                .foregroundStyle(task.isCompleted ? Palette.muted : Palette.ink)
                .strikethrough(task.isCompleted)
                .lineLimit(2)
            Spacer(minLength: 4)

            Menu {
                Button("改名", systemImage: "pencil") {
                    beginTaskRename(task)
                }
                Button("删除", systemImage: "trash", role: .destructive) {
                    model.deleteTask(task.id)
                }
            } label: {
                Image(systemName: "ellipsis")
                    .adaptiveHitTarget(minWidth: 28, minHeight: 30)
            }
            .menuIndicator(.hidden)
            .buttonStyle(ZaichangPlainButtonStyle())
            .accessibilityLabel("\(task.title)的更多操作")
        }
        .frame(minHeight: InteractionMetrics.minimumHitDimension)
    }

    private func selectionRow(
        _ task: FocusTask,
        isSelected: Bool,
        selectedTaskIDs: Binding<Set<FocusTask.ID>>
    ) -> some View {
        Button {
            if isSelected {
                selectedTaskIDs.wrappedValue.remove(task.id)
            } else {
                selectedTaskIDs.wrappedValue.insert(task.id)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                Text(task.title).lineLimit(1)
                Spacer()
            }
            .font(.system(size: 11))
            .foregroundStyle(isSelected ? Palette.amberSoft : Palette.ink)
            .padding(.vertical, 5)
        }
        .buttonStyle(ZaichangPlainButtonStyle())
        .accessibilityLabel("选择 Todo：\(task.title)")
    }

    private func taskEditor(
        title: Binding<String>,
        placeholder: String,
        confirm: @escaping () -> Void,
        cancel: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 6) {
            TextField(placeholder, text: title)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .focused($taskEditorFocused)
                .submitLabel(.done)
                .onSubmit(confirm)
                .onChange(of: title.wrappedValue) { _, newValue in
                    if newValue.count > AppModel.maximumTaskTitleLength {
                        title.wrappedValue = String(newValue.prefix(AppModel.maximumTaskTitleLength))
                    }
                }

            Button(action: confirm) {
                Image(systemName: "checkmark")
                    .adaptiveHitTarget(minWidth: 26, minHeight: 28)
            }
            .buttonStyle(ZaichangPlainButtonStyle())
            .disabled(title.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityLabel("确认")

            Button(action: cancel) {
                Image(systemName: "xmark")
                    .adaptiveHitTarget(minWidth: 26, minHeight: 28)
            }
            .buttonStyle(ZaichangPlainButtonStyle())
            .accessibilityLabel("取消")
        }
        .padding(.horizontal, 8)
        .frame(minHeight: max(38, InteractionMetrics.minimumHitDimension))
        .background(Palette.surface3)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.14)))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func beginAddingTask() {
        guard model.canAddTask else { return }
        editingTaskID = nil
        editingTaskTitle = ""
        newTaskTitle = ""
        isAddingTask = true
        focusTaskEditor()
    }

    private func commitNewTask() {
        guard model.addTask(title: newTaskTitle) else { return }
        newTaskTitle = ""
        isAddingTask = false
        taskEditorFocused = false
    }

    private func cancelAddingTask() {
        newTaskTitle = ""
        isAddingTask = false
        taskEditorFocused = false
    }

    private func beginTaskRename(_ task: FocusTask) {
        isAddingTask = false
        newTaskTitle = ""
        editingTaskID = task.id
        editingTaskTitle = task.title
        focusTaskEditor()
    }

    private func commitTaskRename() {
        guard let editingTaskID else { return }
        guard model.renameTask(editingTaskID, title: editingTaskTitle) else { return }
        cancelTaskRename()
    }

    private func cancelTaskRename() {
        editingTaskID = nil
        editingTaskTitle = ""
        taskEditorFocused = false
    }

    private func focusTaskEditor() {
        Task { @MainActor in
            await Task.yield()
            taskEditorFocused = true
        }
    }
}
