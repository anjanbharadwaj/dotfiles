alias gcm='git checkout master'
alias gcmp='git checkout master && git pull origin master'
alias gc='gcm && git checkout'
alias gs='git status'
boat() {
  git add -A && git commit -m "$*"
}
ship() {
  git add -A && git commit -m "$*" && git push origin "$(git rev-parse --abbrev-ref HEAD)"
}
ship() {
  git add -A && git commit -m "shipping" && git push origin "$(git rev-parse --abbrev-ref HEAD)"
}

ship2() {
  # get git diff staged + untracked (but not ignored) changes
  diff=$(git diff --cached && git diff --no-index /dev/null $(git ls-files --others --exclude-standard) 2>/dev/null)

  if [ -z "$diff" ]; then
    echo "No changes to commit."
    return 1
  fi

  # prepare GPT prompt
  json=$(jq -n --arg d "$diff" '{
    model: "gpt-4o-mini",
    messages: [
      { role: "system", content: "You are a senior software engineer. Generate a clear, concise Git commit message based on the following diff. Respond with only the commit message, at most 1 sentence." },
      { role: "user", content: $d }
    ],
    temperature: 0.2
  }')

  # call OpenAI API
  commit_msg=$(curl -s https://api.openai.com/v1/chat/completions \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$json" | jq -r '.choices[0].message.content')

  if [ -z "$commit_msg" ]; then
    echo "Failed to generate commit message."
    return 1
  fi

  final_msg="[LLM-Generated-Commit-Message] $commit_msg"

  git add -A && git commit -m "$final_msg" && git push origin "$(git rev-parse --abbrev-ref HEAD)"
}
