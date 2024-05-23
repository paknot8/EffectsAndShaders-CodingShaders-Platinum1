using UnityEngine;

public class CameraMovement : MonoBehaviour
{
    public float speed = 10f; // Speed of the camera movement

    // Update is called once per frame
    void Update()
    {
        Vector3 direction = Vector3.zero;

        // WASD movement relative to world coordinates
        if (Input.GetKey(KeyCode.W))
        {
            direction += Vector3.forward;
        }
        if (Input.GetKey(KeyCode.S))
        {
            direction += Vector3.back;
        }
        if (Input.GetKey(KeyCode.A))
        {
            direction += Vector3.left;
        }
        if (Input.GetKey(KeyCode.D))
        {
            direction += Vector3.right;
        }

        // Shift to go up
        if (Input.GetKey(KeyCode.Space))
        {
            direction += Vector3.up;
        }

        // Ctrl to go down
        if (Input.GetKey(KeyCode.LeftControl))
        {
            direction += Vector3.down;
        }

        // Normalize the direction to ensure consistent speed in all directions
        direction = direction.normalized;

        // Move the camera using world coordinates
        transform.position += direction * speed * Time.deltaTime;
    }
}
