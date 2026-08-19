import SkipAbbreviatedExamples from './rules/skip-abbreviated-examples.js'

export default function CustomRulesPlugin() {
  return {
    id: 'custom-rules',
    rules: {
      oas3: {
        'skip-abbreviated-examples': SkipAbbreviatedExamples,
      }
    }
  }
}
