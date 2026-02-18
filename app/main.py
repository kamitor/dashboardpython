import sys
from PySide6.QtWidgets import QApplication, QMainWindow, QPushButton, QLabel, QVBoxLayout, QWidget
import subprocess
import os

APP_VERSION = os.environ.get("APP_VERSION", "dev").lstrip("v")
BUILD_NUMBER = os.environ.get("BUILD_NUMBER", "0")
COMMIT_SHA = os.environ.get("COMMIT_SHA", "unknown")[:7]


class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()

        w.setWindowTitle(f"ResilienceScan v{APP_VERSION} build {BUILD_NUMBER} ({COMMIT_SHA})")


        layout = QVBoxLayout()

        self.label = QLabel("Press the button to run Python task")
        layout.addWidget(self.label)

        self.button = QPushButton("Run Task")
        self.button.clicked.connect(self.run_task)
        layout.addWidget(self.button)

        container = QWidget()
        container.setLayout(layout)

        self.setCentralWidget(container)

    def run_task(self):
        result = subprocess.run(
            ["python", "--version"],
            capture_output=True,
            text=True
        )
        self.label.setText(result.stdout.strip())

app = QApplication(sys.argv)
window = MainWindow()
window.show()
app.exec()
