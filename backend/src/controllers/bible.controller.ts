import type { Request, Response } from 'express';

// Re-export JS controller under TS name expected by bible.routes.ts
// eslint-disable-next-line @typescript-eslint/no-var-requires
const jsController = require('./bibleController.js');

export const bibleController: {
  translations: (req: Request, res: Response) => Promise<Response> | Response;
  books: (req: Request, res: Response) => Promise<Response> | Response;
  chapter: (req: Request, res: Response) => Promise<Response> | Response;
  search: (req: Request, res: Response) => Promise<Response> | Response;
} = jsController;
