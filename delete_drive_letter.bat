if exist X: (
  subst X: /d
  echo "Deleted drive X:"
) else (
  echo "Drive X: not exists"
)
timeout 5