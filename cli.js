#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const COLORS = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
  red: '\x1b[31m',
  white: '\x1b[37m'
};

function log(message, color = '') {
  console.log(`${color}${message}${COLORS.reset}`);
}

function copyRecursiveSync(src, dest) {
  const exists = fs.existsSync(src);
  const stats = exists && fs.statSync(src);
  const isDirectory = exists && stats.isDirectory();

  if (isDirectory) {
    if (!fs.existsSync(dest)) {
      fs.mkdirSync(dest, { recursive: true });
    }
    fs.readdirSync(src).forEach(childItemName => {
      copyRecursiveSync(
        path.join(src, childItemName),
        path.join(dest, childItemName)
      );
    });
  } else {
    fs.copyFileSync(src, dest);
  }
}

async function install() {
  log('\n🧠 Micro-Claude Installation', COLORS.bright + COLORS.cyan);
  log('==============================\n', COLORS.cyan);

  const targetDir = process.cwd();

  // Check if .claude/commands with mc-* files already exists
  const commandsDir = path.join(targetDir, '.claude', 'commands');
  const mcFiles = fs.existsSync(commandsDir) &&
    fs.readdirSync(commandsDir).some(f => f.startsWith('mc-'));

  if (mcFiles) {
    log('⚠️  Micro-Claude commands already exist in this project!', COLORS.yellow);
    const readline = require('readline').createInterface({
      input: process.stdin,
      output: process.stdout
    });

    const answer = await new Promise(resolve => {
      readline.question('Do you want to overwrite? (y/N): ', resolve);
    });
    readline.close();

    if (answer.toLowerCase() !== 'y') {
      log('Installation cancelled.', COLORS.yellow);
      process.exit(0);
    }
  }

  try {
    log('📦 Installing Micro-Claude files...', COLORS.blue);

    // Create .claude/commands directory if it doesn't exist
    if (!fs.existsSync(commandsDir)) {
      fs.mkdirSync(commandsDir, { recursive: true });
    }

    // Copy command files from the package
    const commandsSource = path.join(__dirname, '.claude', 'commands');
    if (fs.existsSync(commandsSource)) {
      copyRecursiveSync(commandsSource, commandsDir);
      log('✅ Installed Micro-Claude commands', COLORS.green);
      log('   • /mc:interrogate - Deep user interrogation', COLORS.white);
      log('   • /mc:mini-explode - High-level task explosion', COLORS.white);
      log('   • /mc:explode - Fine-grained task explosion', COLORS.white);
      log('   • /mc:implement - Task implementation loop', COLORS.white);
    }

    // Create .micro-claude directory for task storage
    const microClaudeDir = path.join(targetDir, '.micro-claude');
    if (!fs.existsSync(microClaudeDir)) {
      fs.mkdirSync(microClaudeDir, { recursive: true });
      log('✅ Created .micro-claude directory', COLORS.green);
    }

    log('\n✨ Micro-Claude installed successfully!', COLORS.bright + COLORS.green);

    log('\n📋 Workflow:', COLORS.cyan);
    log('1. /mc:interrogate  → Creates detailed plan.md', COLORS.white);
    log('2. /mc:mini-explode → Explodes into high-level tasks', COLORS.white);
    log('   /mc:explode      → Explodes into atomic tasks', COLORS.white);
    log('3. /mc:implement    → Implements tasks with notes', COLORS.white);

    log('\n📁 Files created per task:', COLORS.cyan);
    log('   .micro-claude/[task-name]/', COLORS.white);
    log('   ├── plan.md    # Detailed specifications', COLORS.white);
    log('   ├── prd.json   # Task definitions', COLORS.white);
    log('   └── notes.md   # Implementation notes', COLORS.white);

    log('\nFor more information, visit:', COLORS.blue);
    log('https://github.com/ayoubben18/micro-claude', COLORS.white);

  } catch (error) {
    log(`\n❌ Installation failed: ${error.message}`, COLORS.red);
    process.exit(1);
  }
}

// Parse command line arguments
const args = process.argv.slice(2);
const command = args[0];

if (!command || command === 'install') {
  install();
} else if (command === '--help' || command === '-h') {
  log('\n📚 Micro-Claude CLI', COLORS.bright + COLORS.cyan);
  log('===================\n', COLORS.cyan);
  log('Usage:', COLORS.yellow);
  log('  npx micro-claude          Install Micro-Claude in current project');
  log('  npx micro-claude install  Install Micro-Claude in current project');
  log('  npx micro-claude --help   Show this help message');
  log('\nCommands installed:', COLORS.yellow);
  log('  /mc:interrogate   Deep user interrogation to create plan');
  log('  /mc:mini-explode  Explode plan into high-level tasks');
  log('  /mc:explode       Explode plan into atomic tasks');
  log('  /mc:implement     Implement tasks with notes tracking');
  log('\nMore info: https://github.com/ayoubben18/micro-claude', COLORS.blue);
} else if (command === '--version' || command === '-v') {
  const packageJson = require('./package.json');
  log(`micro-claude v${packageJson.version}`, COLORS.cyan);
} else {
  log(`Unknown command: ${command}`, COLORS.red);
  log('Run "npx micro-claude --help" for usage information', COLORS.yellow);
  process.exit(1);
}
