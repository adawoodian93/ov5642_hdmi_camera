if not exist X: (
  subst X: %cd%
  echo "Created drive X:"
) else (
  echo "Drive X: already exists"
)
timeout 5