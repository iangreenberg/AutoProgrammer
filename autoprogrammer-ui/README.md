# AutoProgrammer UI

A React-based frontend service with a floating, draggable AI assistant for asking software development questions. This UI component communicates with an API Gateway to fetch AI-generated responses and Cursor-optimized prompts.

## Features

- 🤖 **Floating, Draggable Assistant**: A simple emoji character that can be positioned anywhere on the screen
- 💬 **Question Input**: Text area for submitting software development questions
- 🔄 **API Integration**: Communicates with the API Gateway (`localhost:4000/ask`)
- 📝 **Response Display**: Shows structured AI-generated responses

## Prerequisites

- Node.js (v14 or later)
- npm or yarn
- API Gateway running on `localhost:4000`

## Installation

1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd autoprogrammer-ui
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

## Running the Application

1. Start the development server:
   ```bash
   npm run dev
   ```

2. Open your browser and navigate to `http://localhost:5173` (or the URL shown in your terminal)

3. The AI assistant will appear as a draggable emoji (🤖) in the corner of the screen

## Usage

1. Click on the 🤖 emoji to open the assistant panel
2. Type your software development question in the text area
3. Click the "Ask" button to submit your query
4. The AI-generated response will appear in the response box

## API Integration

The frontend communicates with the API Gateway at `http://localhost:4000/ask`. Ensure that your API Gateway is running and properly configured to handle requests.

## Technologies Used

- React + Vite
- React-Draggable
- Axios for API calls
- CSS for styling

## Note

This is a frontend-only implementation. It requires a properly configured API Gateway running on `localhost:4000` to function correctly.
