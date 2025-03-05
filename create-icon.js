const { createCanvas } = require('canvas');
const fs = require('fs');
const path = require('path');

// Create a high-contrast, vivid robot icon
function createRobotIcon() {
  // Larger canvas for higher resolution
  const canvas = createCanvas(1024, 1024);
  const ctx = canvas.getContext('2d');
  
  // Colors with higher contrast
  const colors = {
    background: '#0f2e4c',
    robotHead: '#2563EB', // Brighter blue
    robotFace: '#1E40AF',
    highlight: '#FFFFFF',
    eyeGlow: '#10B981', // Vivid green for visibility
    antennaGlow: '#F59E0B', // Bright amber
    mouth: '#F472B6', // Pink mouth for contrast
    circuits: '#60A5FA',
  };
  
  // Create a dark gradient background
  const bgGradient = ctx.createRadialGradient(
    canvas.width / 2, canvas.height / 2, 0,
    canvas.width / 2, canvas.height / 2, canvas.width
  );
  bgGradient.addColorStop(0, '#1E293B');
  bgGradient.addColorStop(1, '#0F172A');
  ctx.fillStyle = bgGradient;
  ctx.fillRect(0, 0, canvas.width, canvas.height);
  
  // Add a subtle glow to the entire icon
  ctx.shadowColor = '#60A5FA';
  ctx.shadowBlur = 30;
  
  // Draw the robot head - made larger and more defined
  ctx.fillStyle = colors.robotHead;
  roundRect(ctx, 174, 174, 676, 676, 80, true);
  
  // Inner face panel with sharper contrast
  ctx.fillStyle = colors.robotFace;
  roundRect(ctx, 224, 224, 576, 576, 50, true);
  
  // Add metallic highlight on top
  const headHighlight = ctx.createLinearGradient(0, 174, 0, 250);
  headHighlight.addColorStop(0, 'rgba(255, 255, 255, 0.8)');
  headHighlight.addColorStop(1, 'rgba(255, 255, 255, 0)');
  ctx.fillStyle = headHighlight;
  ctx.beginPath();
  ctx.moveTo(174, 174);
  ctx.lineTo(850, 174);
  ctx.lineTo(850, 250);
  ctx.lineTo(174, 250);
  ctx.closePath();
  ctx.fill();
  
  // Draw antenna with thick outline
  ctx.strokeStyle = '#0F172A';
  ctx.lineWidth = 20;
  ctx.beginPath();
  ctx.moveTo(512, 100);
  ctx.lineTo(512, 174);
  ctx.stroke();
  
  // Add antenna ball with glow
  ctx.shadowColor = colors.antennaGlow;
  ctx.shadowBlur = 40;
  ctx.fillStyle = colors.antennaGlow;
  ctx.beginPath();
  ctx.arc(512, 90, 40, 0, Math.PI * 2);
  ctx.fill();
  
  // Reset shadow for other elements
  ctx.shadowBlur = 10;
  
  // Draw ears/side panels with stronger definition
  ctx.fillStyle = colors.robotHead;
  // Left ear
  roundRect(ctx, 94, 300, 80, 200, 20, true);
  // Right ear
  roundRect(ctx, 850, 300, 80, 200, 20, true);
  
  // Draw eyes with strong glow
  ctx.shadowColor = colors.eyeGlow;
  ctx.shadowBlur = 30;
  ctx.fillStyle = colors.eyeGlow;
  
  // Left eye - larger and more defined
  ctx.beginPath();
  ctx.arc(350, 400, 70, 0, Math.PI * 2);
  ctx.fill();
  
  // Right eye - larger and more defined
  ctx.beginPath();
  ctx.arc(674, 400, 70, 0, Math.PI * 2);
  ctx.fill();
  
  // Add eye highlights for realism
  ctx.shadowBlur = 0;
  ctx.fillStyle = colors.highlight;
  
  // Left eye highlight
  ctx.beginPath();
  ctx.arc(330, 380, 25, 0, Math.PI * 2);
  ctx.fill();
  
  // Right eye highlight
  ctx.beginPath();
  ctx.arc(654, 380, 25, 0, Math.PI * 2);
  ctx.fill();
  
  // Draw mouth - smiling with thick outline
  ctx.strokeStyle = '#000000';
  ctx.lineWidth = 10;
  ctx.fillStyle = colors.mouth;
  ctx.beginPath();
  ctx.arc(512, 600, 120, 0.1 * Math.PI, 0.9 * Math.PI);
  ctx.stroke();
  ctx.fill();
  
  // Add circuit pattern details on face - more prominent
  ctx.strokeStyle = colors.circuits;
  ctx.lineWidth = a = 8;
  
  // Left side circuits
  drawCircuits(ctx, 250, 500, 150, 60);
  
  // Right side circuits
  drawCircuits(ctx, 650, 500, 150, 60);
  
  // Bottom circuits
  drawCircuits(ctx, 450, 700, 200, 30);
  
  // Add circular border for extra visibility
  ctx.strokeStyle = '#FFFFFF';
  ctx.lineWidth = 20;
  ctx.beginPath();
  ctx.arc(512, 512, 480, 0, Math.PI * 2);
  ctx.stroke();
  
  // Save the icon to the specified directory
  const iconDir = path.join(__dirname, 'icons');
  
  // Create directory if it doesn't exist
  if (!fs.existsSync(iconDir)) {
    fs.mkdirSync(iconDir, { recursive: true });
  }
  
  const iconPath = path.join(iconDir, 'icon.png');
  const out = fs.createWriteStream(iconPath);
  const stream = canvas.createPNGStream();
  stream.pipe(out);
  
  out.on('finish', () => {
    console.log(`Ultra-visible robot icon created at ${iconPath}`);
  });
}

// Helper function to draw rounded rectangles
function roundRect(ctx, x, y, width, height, radius, fill) {
  ctx.beginPath();
  ctx.moveTo(x + radius, y);
  ctx.lineTo(x + width - radius, y);
  ctx.quadraticCurveTo(x + width, y, x + width, y + radius);
  ctx.lineTo(x + width, y + height - radius);
  ctx.quadraticCurveTo(x + width, y + height, x + width - radius, y + height);
  ctx.lineTo(x + radius, y + height);
  ctx.quadraticCurveTo(x, y + height, x, y + height - radius);
  ctx.lineTo(x, y + radius);
  ctx.quadraticCurveTo(x, y, x + radius, y);
  ctx.closePath();
  if (fill) {
    ctx.fill();
  } else {
    ctx.stroke();
  }
}

// Helper function to draw circuit patterns
function drawCircuits(ctx, startX, startY, length, gap) {
  ctx.beginPath();
  ctx.moveTo(startX, startY);
  ctx.lineTo(startX + length, startY);
  ctx.moveTo(startX + length - gap, startY);
  ctx.lineTo(startX + length - gap, startY + gap);
  ctx.lineTo(startX + length - gap * 2, startY + gap);
  ctx.stroke();
}

createRobotIcon(); 